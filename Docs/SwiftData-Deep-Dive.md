# SwiftData 완전 해부 + 용어 사전

---

## 1. 아키텍처 레이어 (Architecture Stack)

```
┌─────────────────────────────────────────────────┐
│                   SwiftData                      │  ← Swift Macros + Modern API
├─────────────────────────────────────────────────┤
│                   Core Data                      │  ← NSPersistentContainer, NSManagedObjectContext
├─────────────────────────────────────────────────┤
│              SQLite (or Binary/XML)              │  ← Persistent Store
├─────────────────────────────────────────────────┤
│                 File System                      │  ← .sqlite 파일
└─────────────────────────────────────────────────┘
```

### 용어 정리

**래퍼(Wrapper)**
```
기존 것을 감싸서 더 쉽게 사용할 수 있게 만든 것

예시:
┌──────────────────────┐
│  SwiftData (래퍼)     │  ← 개발자가 사용하는 쉬운 API
│  ┌────────────────┐  │
│  │   Core Data    │  │  ← 실제로 일하는 복잡한 코드
│  └────────────────┘  │
└──────────────────────┘

비유: 리모컨(래퍼) → TV 내부 회로(실제 구현)
     - 리모컨 버튼만 누르면 됨
     - 내부가 어떻게 동작하는지 몰라도 됨
```

**API (Application Programming Interface)**
```
프로그램끼리 소통하는 규칙/방법

SwiftData API 예시:
- modelContext.insert(baby)   ← "이 객체 저장해줘"
- modelContext.fetch(...)     ← "이 조건으로 찾아줘"
- modelContext.save()         ← "변경사항 확정해줘"

비유: 식당 메뉴판
     - 메뉴판에 있는 것만 주문 가능
     - 주방이 어떻게 요리하는지는 몰라도 됨
```

**Persistent Store (영구 저장소)**
```
앱을 종료해도 데이터가 살아있는 저장 공간

종류:
- SQLite: 관계형 데이터베이스 파일 (.sqlite)
- Binary: 바이너리 파일 (빠름, 사람이 못 읽음)
- XML: XML 파일 (느림, 사람이 읽을 수 있음)
- In-Memory: 메모리에만 (앱 종료 시 삭제)

우리 프로젝트:
- liveValue → SQLite (영구)
- previewValue → In-Memory (임시)
```

---

## 2. ORM (Object-Relational Mapping) 패턴

### 용어 정리

**ORM (Object-Relational Mapping)**
```
객체(Object)와 관계형 데이터베이스(Relational DB)를 연결(Mapping)하는 기술

문제:
- Swift: class Baby { var name: String }  ← 객체 지향
- SQLite: CREATE TABLE babies (name TEXT) ← 테이블 구조
- 이 둘은 완전히 다른 세계

ORM이 하는 일:
┌─────────────┐         ┌─────────────┐
│ Baby 객체    │  ←ORM→  │ babies 테이블 │
│ name = "서연" │         │ name = '서연' │
└─────────────┘         └─────────────┘

baby.name = "민준"  →  UPDATE babies SET name = '민준'
modelContext.save()     WHERE id = 1;
```

**임피던스 불일치 (Impedance Mismatch)**
```
원래 전기공학 용어. 두 시스템이 서로 안 맞아서 에너지 손실이 생기는 현상.
소프트웨어에서는 "두 세계가 안 맞아서 생기는 문제들"

객체 세계 vs 관계형 세계의 불일치:

1. Identity (정체성) 불일치
   - 객체: baby1 === baby2 (메모리 주소가 같으면 같은 객체)
   - DB: id = 1 (PRIMARY KEY가 같으면 같은 레코드)
   
2. Association (관계) 불일치
   - 객체: baby.logs (객체가 다른 객체를 직접 참조)
   - DB: activity_logs.baby_id = 1 (숫자로 연결, JOIN 필요)

3. Inheritance (상속) 불일치
   - 객체: class Dog extends Animal (상속 가능)
   - DB: 테이블은 상속 개념이 없음
```

**PRIMARY KEY (기본 키)**
```
테이블에서 각 행(row)을 고유하게 식별하는 값

CREATE TABLE babies (
    id INTEGER PRIMARY KEY,  ← 이게 기본 키
    name TEXT
);

규칙:
- 중복 불가 (같은 id 두 개 못 가짐)
- NULL 불가 (비어있으면 안 됨)
- 변경 지양 (바꾸면 연결된 모든 곳 수정해야 함)
```

**FOREIGN KEY (외래 키)**
```
다른 테이블의 PRIMARY KEY를 참조하는 값

babies 테이블:          activity_logs 테이블:
┌────┬───────┐          ┌────┬─────────┬──────────┐
│ id │ name  │          │ id │ baby_id │ type     │
├────┼───────┤          ├────┼─────────┼──────────┤
│ 1  │ 서연   │ ←────────│ 1  │ 1       │ feeding  │
│ 2  │ 민준   │          │ 2  │ 1       │ diaper   │
└────┴───────┘          │ 3  │ 2       │ bath     │
                        └────┴─────────┴──────────┘
                              ↑
                          FOREIGN KEY
                     (babies.id를 참조)
```

**JOIN**
```
여러 테이블을 연결해서 하나로 합치는 SQL 연산

SELECT babies.name, activity_logs.type
FROM babies
JOIN activity_logs ON babies.id = activity_logs.baby_id;

결과:
┌───────┬──────────┐
│ name  │ type     │
├───────┼──────────┤
│ 서연   │ feeding  │
│ 서연   │ diaper   │
│ 민준   │ bath     │
└───────┴──────────┘
```

**정규화 (Normalization)**
```
데이터 중복을 제거하기 위해 테이블을 분리하는 과정

나쁜 예 (비정규화):
┌────┬───────┬──────────┬───────────┐
│ id │ baby  │ log_type │ baby_birth│
├────┼───────┼──────────┼───────────┤
│ 1  │ 서연   │ feeding  │ 2024-01-01│  ← 서연 정보 중복!
│ 2  │ 서연   │ diaper   │ 2024-01-01│  ← 서연 정보 중복!
│ 3  │ 서연   │ bath     │ 2024-01-01│  ← 서연 정보 중복!
└────┴───────┴──────────┴───────────┘

좋은 예 (정규화):
babies:                 activity_logs:
┌────┬───────┬───────────┐   ┌────┬─────────┬──────────┐
│ id │ name  │ birth     │   │ id │ baby_id │ type     │
├────┼───────┼───────────┤   ├────┼─────────┼──────────┤
│ 1  │ 서연   │ 2024-01-01│   │ 1  │ 1       │ feeding  │
└────┴───────┴───────────┘   │ 2  │ 1       │ diaper   │
                             │ 3  │ 1       │ bath     │
                             └────┴─────────┴──────────┘
```

---

## 3. @Model 매크로의 컴파일 타임 마법

### 용어 정리

**매크로 (Macro)**
```
코드를 자동으로 생성하는 코드

작성한 코드:
@Model
class Baby {
    var name: String
}

컴파일러가 실제로 만드는 코드:
class Baby: PersistentModel, Observable {
    private var _backingData: ...
    private var _observationRegistrar: ...
    
    var name: String {
        get { _backingData[\.name] }
        set { 
            _observationRegistrar.notify(...)
            _backingData[\.name] = newValue 
        }
    }
    
    static var schemaMetadata: [...] { ... }
    
    // ... 수백 줄의 코드
}

비유: 
- 매크로 = 요리 레시피
- 컴파일러 = 요리사
- "스테이크"라고 쓰면 → 요리사가 전체 조리 과정을 알아서 수행
```

**컴파일 타임 (Compile Time) vs 런타임 (Runtime)**
```
컴파일 타임: 코드를 실행 파일로 변환하는 시점
           (개발자가 빌드 버튼 누를 때)
           
런타임: 앱이 실제로 실행되는 시점
       (사용자가 앱을 사용할 때)

┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ 소스 코드     │ →→→ │ 컴파일러      │ →→→ │ 실행 파일    │
│ (.swift)     │     │ (변환)        │     │ (.app)      │
└──────────────┘     └──────────────┘     └──────────────┘
                          ↑                      ↑
                     컴파일 타임               런타임

매크로는 컴파일 타임에 동작 → 앱 실행 시 이미 코드가 다 만들어져 있음
리플렉션은 런타임에 동작 → 앱 실행 중에 타입 정보를 분석 (느림)
```

**메타프로그래밍 (Metaprogramming)**
```
"프로그램을 만드는 프로그램"

일반 프로그래밍:
func add(a: Int, b: Int) -> Int { a + b }
→ 데이터를 처리하는 코드

메타프로그래밍:
@Model class Baby { ... }
→ 코드를 생성하는 코드 (매크로가 getter/setter 등을 자동 생성)

실제 예시 - @Model이 생성하는 것들:
1. PersistentModel 프로토콜 준수 코드
2. Observable 프로토콜 준수 코드
3. 모든 프로퍼티의 getter/setter
4. 스키마 메타데이터
5. 인코딩/디코딩 로직
```

**AOP (Aspect-Oriented Programming, 관점 지향 프로그래밍)**
```
핵심 로직과 부가 기능을 분리하는 프로그래밍 패러다임

문제: 모든 프로퍼티에 로깅을 추가하고 싶다면?

AOP 없이:
var name: String {
    get { 
        print("name 읽음")  // ← 반복!
        return _name 
    }
    set { 
        print("name 변경: \(newValue)")  // ← 반복!
        _name = newValue 
    }
}
var birthDate: Date {
    get { 
        print("birthDate 읽음")  // ← 반복!
        return _birthDate 
    }
    // ... 모든 프로퍼티에 같은 코드 반복
}

AOP 사용 (SwiftData):
@Model  // ← 이 한 줄로 모든 프로퍼티에 변경 추적 자동 삽입
class Baby {
    var name: String
    var birthDate: Date
}

"Aspect" = 관점, 관심사
- 핵심 관심사: 데이터 저장
- 횡단 관심사: 변경 추적, 로깅, 트랜잭션 등
              (여러 곳에 걸쳐있는 공통 기능)
```

**리플렉션 (Reflection)**
```
프로그램이 실행 중에 자기 자신의 구조를 들여다보는 기능

Swift 리플렉션 예시:
let baby = Baby(name: "서연", birthDate: Date())
let mirror = Mirror(reflecting: baby)

for child in mirror.children {
    print("\(child.label!): \(child.value)")
}
// 출력: name: 서연
//      birthDate: 2024-01-01

장점: 유연함 (어떤 타입이든 분석 가능)
단점: 느림 (런타임에 타입 정보를 분석해야 함)

SwiftData는 리플렉션 대신 매크로 사용:
- 컴파일 타임에 미리 스키마 정보를 코드로 생성
- 런타임에 분석할 필요 없음 → 빠름
```

**프로퍼티 래퍼 (Property Wrapper)**
```
프로퍼티의 getter/setter에 추가 로직을 넣는 Swift 기능

직접 구현 예시:
@propertyWrapper
struct Clamped {
    var wrappedValue: Int {
        didSet { wrappedValue = min(max(wrappedValue, 0), 100) }
    }
}

struct Progress {
    @Clamped var percent: Int  // 항상 0~100 사이
}

var p = Progress(percent: 150)
print(p.percent)  // 100 (자동으로 제한됨)

SwiftData의 @Model은 내부적으로 비슷한 방식으로:
- 프로퍼티 읽기 → 변경 추적 등록
- 프로퍼티 쓰기 → 변경 추적 + UI 업데이트 알림
```

**Dirty Checking (더티 체킹)**
```
객체가 "더러워졌는지" (변경되었는지) 확인하는 기법

Clean 상태: DB와 메모리 객체가 동일
Dirty 상태: 메모리 객체가 변경됨, DB는 아직 안 변함

┌──────────────────┐       ┌──────────────────┐
│   Memory         │       │   Database       │
│ ┌──────────────┐ │       │ ┌──────────────┐ │
│ │ name: "서연"  │ │  ==   │ │ name: "서연"  │ │  CLEAN
│ └──────────────┘ │       │ └──────────────┘ │
└──────────────────┘       └──────────────────┘

baby.name = "민준"

┌──────────────────┐       ┌──────────────────┐
│   Memory         │       │   Database       │
│ ┌──────────────┐ │       │ ┌──────────────┐ │
│ │ name: "민준"  │ │  !=   │ │ name: "서연"  │ │  DIRTY!
│ │ [DIRTY FLAG] │ │       │ └──────────────┘ │
│ └──────────────┘ │       └──────────────────┘
└──────────────────┘

modelContext.save()  ← Dirty한 객체만 DB에 반영
```

---

## 4. Faulting과 Lazy Loading

### 용어 정리

**Lazy Loading (지연 로딩)**
```
데이터를 당장 필요할 때까지 로드하지 않는 기법

Eager Loading (즉시 로딩):
let babies = fetch()  // 모든 baby 데이터를 바로 메모리에 로드
// 메모리 사용량: 높음
// 초기 로딩 시간: 김

Lazy Loading (지연 로딩):
let babies = fetch()  // baby의 "껍데기"만 로드
print(babies[0].name) // 이 순간에 실제 데이터 로드
// 메모리 사용량: 낮음 (필요한 것만)
// 초기 로딩 시간: 짧음

비유:
- Eager: 도서관의 모든 책을 집에 가져옴
- Lazy: 책 목록만 가져오고, 읽을 책만 그때그때 빌림
```

**Fault (폴트)**
```
실제 데이터가 없는 "껍데기" 객체

Unfired Fault (발화 전):
┌─────────────────────────┐
│ Baby Fault              │
│ ├─ objectID: 12345     │  ← 이것만 있음
│ ├─ name: ???            │  ← 아직 모름
│ └─ birthDate: ???       │  ← 아직 모름
└─────────────────────────┘

Fired Fault (발화 후) = Realized Object:
baby.name 접근 → DB 쿼리 자동 실행
┌─────────────────────────┐
│ Baby (Realized)         │
│ ├─ objectID: 12345     │
│ ├─ name: "서연"          │  ← 로드됨!
│ └─ birthDate: 2024-01-01│  ← 로드됨!
└─────────────────────────┘

"Fault"라는 이름의 유래:
- Page Fault (페이지 폴트)에서 따옴
- OS가 메모리에 없는 페이지에 접근하면 디스크에서 로드하는 것과 유사
```

**Virtual Proxy Pattern (가상 프록시 패턴)**
```
GoF 디자인 패턴 중 하나. 실제 객체 대신 대리자가 앞에 서는 패턴.

┌────────────┐      ┌────────────┐      ┌────────────┐
│  Client    │ ──→  │   Proxy    │ ──→  │ Real Object│
│ (코드)     │      │ (대리자)    │      │ (실제 객체) │
└────────────┘      └────────────┘      └────────────┘

예시 - 이미지 로딩:
class ImageProxy {
    var realImage: Image? = nil  // 처음엔 없음
    
    func display() {
        if realImage == nil {
            realImage = loadFromDisk()  // 필요할 때 로드
        }
        realImage!.display()
    }
}

SwiftData의 Fault = Virtual Proxy
- 처음엔 objectID만 있는 프록시
- 프로퍼티 접근 시 실제 데이터 로드
```

**Demand Paging (요구 페이징)**
```
OS(운영체제)의 가상 메모리 관리 기법

물리 메모리 (RAM): 8GB
가상 메모리 공간: 128GB (프로그램이 사용할 수 있다고 "생각하는" 메모리)

┌─────────────────────────────────────────┐
│         Virtual Memory (가상)            │
│  ┌─────┬─────┬─────┬─────┬─────┬─────┐  │
│  │ P1  │ P2  │ P3  │ P4  │ P5  │ ... │  │
│  └──┬──┴──┬──┴─────┴─────┴─────┴─────┘  │
│     │     │                              │
└─────┼─────┼──────────────────────────────┘
      │     │
      ▼     ▼
┌─────────────────┐
│ Physical Memory │  ← 실제로는 필요한 페이지만 로드
│  ┌─────┬─────┐  │
│  │ P1  │ P2  │  │
│  └─────┴─────┘  │
└─────────────────┘

P3에 접근하면?
→ "Page Fault" 발생
→ 디스크에서 P3 로드
→ 물리 메모리에 적재

SwiftData도 동일한 원리:
- 모든 객체가 메모리에 있는 "척"
- 실제론 접근할 때만 DB에서 로드
```

---

## 5. ModelContext와 Unit of Work 패턴

### 용어 정리

**Unit of Work (작업 단위) 패턴**
```
Martin Fowler가 정의한 엔터프라이즈 패턴

"비즈니스 트랜잭션 동안 변경된 객체들을 추적하고,
 트랜잭션이 끝날 때 모든 변경을 한 번에 DB에 반영"

시나리오:
1. 아기 정보 수정
2. 수유 기록 추가
3. 체중 기록 삭제

Unit of Work 없이:
baby.name = "민준"      → INSERT ... (바로 DB 접근)
log = ActivityLog(...)  → INSERT ... (바로 DB 접근)
deleteWeight(...)       → DELETE ... (바로 DB 접근)
// 3번의 개별 DB 접근
// 중간에 실패하면? 일부만 저장된 불완전한 상태!

Unit of Work 사용:
┌─────────────────────────────────┐
│ ModelContext (Unit of Work)     │
│                                 │
│ baby.name = "민준"    → 추적     │
│ insert(log)          → 추적     │
│ delete(weight)       → 추적     │
│                                 │
│ save() 호출:                    │
│   BEGIN TRANSACTION;            │
│   UPDATE babies SET ...         │
│   INSERT INTO logs ...          │
│   DELETE FROM weights ...       │
│   COMMIT;                       │  ← 한 번에, 전부 성공 or 전부 실패
└─────────────────────────────────┘
```

**트랜잭션 (Transaction)**
```
"전부 성공하거나 전부 실패해야 하는 작업 묶음"

은행 송금 예시:
1. A 계좌에서 100만원 출금
2. B 계좌에 100만원 입금

만약 1은 성공하고 2가 실패하면?
→ 100만원이 증발! (절대 안 됨)

트랜잭션으로 묶으면:
BEGIN TRANSACTION;
  UPDATE accounts SET balance = balance - 100 WHERE id = 'A';
  UPDATE accounts SET balance = balance + 100 WHERE id = 'B';
COMMIT;  -- 둘 다 성공해야 반영

만약 실패하면:
ROLLBACK;  -- 모든 변경 취소, 원래 상태로
```

**ACID**
```
트랜잭션이 지켜야 할 4가지 속성

A - Atomicity (원자성)
    "전부 되거나, 전부 안 되거나"
    100개 INSERT 중 1개 실패 → 100개 다 취소

C - Consistency (일관성)
    "규칙을 항상 만족"
    잔고가 음수가 되면 안 됨 → 규칙 위반 시 트랜잭션 실패

I - Isolation (격리성)
    "다른 트랜잭션이 중간 상태를 못 봄"
    A가 송금 중일 때, B가 조회하면 송금 전/후 상태 중 하나만 보임

D - Durability (지속성)
    "커밋되면 영구 보존"
    COMMIT 후 정전이 나도 데이터 유지
```

**Identity Map (아이덴티티 맵) 패턴**
```
"같은 DB 레코드는 메모리에 하나의 인스턴스만"

Identity Map 없이:
let baby1 = fetch(id: 1)  // 새 인스턴스 생성
let baby2 = fetch(id: 1)  // 또 새 인스턴스 생성
baby1 === baby2  // false! 다른 객체!

baby1.name = "민준"
print(baby2.name)  // "서연" (업데이트 안 됨!)
// → 동기화 문제 발생

Identity Map 사용:
┌─────────────────────────────────┐
│ Identity Map                    │
│ {                               │
│   ObjectID(1): Baby("서연"),    │
│   ObjectID(2): Baby("민준")     │
│ }                               │
└─────────────────────────────────┘

let baby1 = fetch(id: 1)  // Map에서 반환 (또는 새로 만들어 Map에 저장)
let baby2 = fetch(id: 1)  // Map에서 같은 인스턴스 반환
baby1 === baby2  // true! 같은 객체!

baby1.name = "지우"
print(baby2.name)  // "지우" (같은 객체니까!)
```

---

## 6. @ModelActor와 Swift Concurrency

### 용어 정리

**Thread-Safe (스레드 안전)**
```
여러 스레드가 동시에 접근해도 문제없이 동작하는 것

Thread-Unsafe 예시:
var count = 0

Thread A: count = count + 1  // count 읽기 (0)
Thread B: count = count + 1  // count 읽기 (0) - 동시에!
Thread A: // count 쓰기 (1)
Thread B: // count 쓰기 (1) - 덮어씀!

기대값: 2
실제값: 1  ← 버그!

이런 문제를 "Data Race (데이터 레이스)"라고 함
```

**Data Race (데이터 레이스)**
```
여러 스레드가 동시에 같은 메모리에 접근하고,
최소 하나가 쓰기 작업일 때 발생하는 버그

조건:
1. 두 개 이상의 스레드가
2. 같은 메모리 위치에 접근하고
3. 최소 하나가 쓰기 작업이고
4. 동기화가 없을 때

결과: 예측 불가능한 동작, 크래시, 데이터 손상
```

**Actor (액터)**
```
Swift의 동시성 안전 장치.
"한 번에 하나의 작업만 처리하는 실행 단위"

actor Counter {
    var count = 0
    func increment() { count += 1 }
}

let counter = Counter()

// 여러 Task에서 동시 호출해도 안전
Task { await counter.increment() }  // 대기열에 들어감
Task { await counter.increment() }  // 앞이 끝날 때까지 대기
Task { await counter.increment() }  // 차례 기다림

내부 동작:
┌─────────────────────────────────┐
│ Actor Mailbox (메일함)           │
│ ┌─────┬─────┬─────┐            │
│ │ Msg1│ Msg2│ Msg3│ → 순차 처리  │
│ └─────┴─────┴─────┘            │
└─────────────────────────────────┘
     ↓        ↓        ↓
   처리     대기      대기
```

**Actor Model (액터 모델)**
```
1973년 Carl Hewitt가 제안한 동시성 프로그래밍 수학적 모델

핵심 개념:
1. 모든 것은 Actor
2. Actor는 메시지를 보내고 받음
3. Actor는 메시지를 한 번에 하나씩 처리
4. Actor는 자신만의 상태를 가짐 (외부에서 직접 접근 불가)

비유: 우체통이 있는 집
- 각 집(Actor)은 자기 우체통(Mailbox)이 있음
- 편지(Message)는 우체통에 쌓임
- 집주인은 편지를 하나씩 처리
- 남이 집에 들어와서 뭔가 하는 건 불가능 (메시지로만 소통)
```

**Serial Executor (직렬 실행기)**
```
작업을 순서대로 하나씩 실행하는 것

Serial (직렬):
Task1 → Task2 → Task3
(앞이 끝나야 다음 시작)

Concurrent (동시):
Task1 ──→
Task2 ──→  (동시에 실행)
Task3 ──→

Actor는 Serial Executor 사용:
┌───────────────────────────────────────┐
│ Actor's Serial Queue                   │
│ [Task1] → [Task2] → [Task3] → ...      │
│    ↓                                   │
│ 현재 실행 중                            │
└───────────────────────────────────────┘
```

**async/await**
```
비동기 코드를 동기 코드처럼 읽기 쉽게 쓰는 문법

콜백 지옥 (옛날 방식):
fetchUser { user in
    fetchPosts(user) { posts in
        fetchComments(posts[0]) { comments in
            // 점점 들여쓰기가 깊어짐...
        }
    }
}

async/await (현대 방식):
let user = await fetchUser()
let posts = await fetchPosts(user)
let comments = await fetchComments(posts[0])
// 마치 동기 코드처럼 읽힘

await의 의미:
"여기서 잠시 멈추고 (suspend), 결과가 오면 이어서 (resume)"
```

**Cooperative Scheduling (협력적 스케줄링)**
```
작업들이 서로 "양보"하며 CPU를 나눠 쓰는 방식

Preemptive (선점형): OS가 강제로 작업 전환
- "10ms 지났으니 너 멈춰, 다음 차례"
- 작업이 협조 안 해도 됨

Cooperative (협력형): 작업이 자발적으로 양보
- "await" 지점에서 "나 지금 기다려야 하니 다른 일 해"
- 작업이 양보 안 하면 다른 작업 못 함

Swift async/await은 협력형:
func process() async {
    // 작업 수행
    await network.fetch()  // ← 여기서 양보, 다른 Task 실행 가능
    // 결과 처리
}
```

---

## 7. Predicate와 쿼리 최적화

### 용어 정리

**Predicate (프레디케이트)**
```
"조건을 표현하는 객체"

함수형으로 보면:
(Object) -> Bool  // 객체를 받아서 true/false 반환

예시:
"나이가 18 이상" = Predicate { $0.age >= 18 }
"이름이 '서연'" = Predicate { $0.name == "서연" }

SwiftData의 #Predicate:
#Predicate<Baby> { $0.name == "서연" && $0.gender == .female }
```

**#Predicate 매크로 vs Swift 클로저**
```
Swift 클로저:
let filtered = babies.filter { $0.name == "서연" }
// 1. 모든 babies를 DB에서 메모리로 로드
// 2. 메모리에서 하나씩 조건 검사
// 3. 조건 맞는 것만 남김
// → 느리고 메모리 많이 씀

#Predicate:
let descriptor = FetchDescriptor<Baby>(
    predicate: #Predicate { $0.name == "서연" }
)
// 1. Predicate를 SQL로 변환: WHERE name = '서연'
// 2. DB에서 조건 맞는 것만 로드
// 3. 필요한 데이터만 메모리에
// → 빠르고 메모리 적게 씀
```

**AST (Abstract Syntax Tree, 추상 구문 트리)**
```
코드의 구조를 트리 형태로 표현한 것

코드: a + b * c

         (+)
        /   \
      (a)   (*)
           /   \
         (b)   (c)

#Predicate { $0.name == "서연" } 의 AST:

         (==)
        /    \
   KeyPath   Value
    (name)   ("서연")

이 트리를 순회하면서 SQL로 변환:
→ WHERE name = '서연'
```

**Query Planning (쿼리 계획)**
```
SQL을 실행하기 전에 "어떻게 실행할지" 계획을 세우는 것

SELECT * FROM babies WHERE name = '서연' AND age > 1

가능한 실행 계획:
Plan A: 전체 테이블 스캔 후 조건 필터
        → O(n) 시간
        
Plan B: name 인덱스로 '서연' 찾고, age 조건 필터
        → O(log n) + O(결과 수)
        
Plan C: age 인덱스로 > 1 찾고, name 조건 필터
        → O(log n) + O(결과 수)

DB 옵티마이저가 가장 빠른 계획 선택
```

**Index (인덱스)**
```
데이터를 빠르게 찾기 위한 자료구조 (보통 B-Tree)

인덱스 없이:
┌────┬───────┬─────┐
│ id │ name  │ age │
├────┼───────┼─────┤
│ 1  │ 서연   │ 1   │
│ 2  │ 민준   │ 2   │   WHERE name = '서연' 찾으려면?
│ 3  │ 지우   │ 1   │   → 처음부터 끝까지 다 봐야 함 O(n)
│ .. │ ...   │ ... │
│ 1M │ 하윤   │ 3   │
└────┴───────┴─────┘

인덱스 있으면:
name 인덱스 (B-Tree):
      [민준|서연|지우]
      /     |     \
   [..]   [서연→row1]  [..]
   
WHERE name = '서연' → 인덱스에서 바로 찾음 O(log n)

@Attribute(.unique)는 자동으로 UNIQUE INDEX 생성
```

**B-Tree**
```
데이터베이스에서 가장 많이 쓰는 자료구조

특징:
- 균형 트리 (모든 리프 노드가 같은 깊이)
- 한 노드에 여러 키 저장 (디스크 I/O 최적화)
- 검색, 삽입, 삭제 모두 O(log n)

        [    10   |   20   ]
       /          |         \
[1|5|7]    [12|15|18]    [25|30|40]

찾고자 하는 값: 15
1. 루트에서 시작: 15 > 10, 15 < 20 → 중간 자식으로
2. [12|15|18]에서 15 발견!

높이가 4인 B-Tree는 수십억 개 레코드 처리 가능
(디스크 접근 4번으로 어떤 레코드든 찾음)
```

---

## 8. 스키마 마이그레이션

### 용어 정리

**Schema (스키마)**
```
데이터베이스의 "구조 설계도"

테이블, 컬럼, 타입, 관계 등을 정의

스키마 예시:
┌─────────────────────────────────────┐
│ Table: babies                        │
├─────────────────────────────────────┤
│ id       INTEGER PRIMARY KEY        │
│ name     TEXT NOT NULL              │
│ birthDate REAL                      │
│ gender   TEXT                       │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Table: activity_logs                 │
├─────────────────────────────────────┤
│ id       INTEGER PRIMARY KEY        │
│ baby_id  INTEGER REFERENCES babies  │
│ type     TEXT                       │
│ timestamp REAL                      │
└─────────────────────────────────────┘
```

**Migration (마이그레이션)**
```
스키마 버전을 업그레이드하는 과정

V1 → V2 마이그레이션 예시:

V1 스키마:
┌─────────────┐
│ babies      │
├─────────────┤
│ id          │
│ name        │
└─────────────┘

V2 스키마 (birthDate 추가):
┌─────────────┐
│ babies      │
├─────────────┤
│ id          │
│ name        │
│ birthDate   │  ← 새 컬럼!
└─────────────┘

마이그레이션 SQL:
ALTER TABLE babies ADD COLUMN birthDate REAL;
```

**Lightweight Migration (경량 마이그레이션)**
```
SwiftData/Core Data가 자동으로 처리하는 간단한 스키마 변경

자동 처리되는 것:
✅ 새 프로퍼티 추가 (Optional이거나 기본값 있으면)
✅ 프로퍼티 삭제
✅ 프로퍼티 이름 변경 (@Attribute(originalName:) 사용)
✅ Optional ↔ Non-optional 변경

수동 마이그레이션 필요한 것:
❌ 타입 변경 (String → Int)
❌ 관계 구조 변경
❌ 데이터 변환 필요한 경우
```

**ETL (Extract-Transform-Load)**
```
데이터 이동/변환 파이프라인

Extract (추출): 기존 저장소에서 데이터 읽기
Transform (변환): 데이터 형식/구조 변환
Load (적재): 새 저장소에 데이터 쓰기

마이그레이션과의 관계:
V1 DB → Extract → Transform → Load → V2 DB

예시: 이름을 firstName/lastName으로 분리
Extract: name = "김서연"
Transform: firstName = "서연", lastName = "김"
Load: INSERT ... (firstName: "서연", lastName: "김")
```

---

## 9. SQLite 내부 구조

### 용어 정리

**Z_ 접두사 테이블들**
```
Core Data가 내부적으로 사용하는 테이블들

Z_PRIMARYKEY: 각 Entity의 다음 PK 값 저장
┌────────────────┬────────────┐
│ Z_ENT          │ Z_MAX      │
├────────────────┼────────────┤
│ 1 (Baby)       │ 42         │  ← 다음 Baby는 id=43
│ 2 (ActivityLog)│ 156        │  ← 다음 Log는 id=157
└────────────────┴────────────┘

Z_METADATA: 스키마 버전 등 메타정보

ZBABYENTITY: Baby 실제 데이터 (Z + Entity이름)
Z_PK, Z_ENT, Z_OPT는 Core Data 관리용 컬럼
```

**Optimistic Locking (낙관적 잠금)**
```
"충돌이 거의 없을 거라고 낙관하고, 충돌 시에만 처리"

Z_OPT 컬럼 = 버전 번호

사용자 A가 수정:
1. 읽기: Baby(id=1, name="서연", Z_OPT=5)
2. 수정: name = "민준"
3. 저장 시도: UPDATE ... WHERE id=1 AND Z_OPT=5
              SET name="민준", Z_OPT=6
              
만약 그 사이 사용자 B가 먼저 수정했다면:
- Z_OPT가 이미 6으로 변경됨
- A의 UPDATE가 0 rows affected
- → 충돌 감지! 다시 시도하거나 사용자에게 알림

Pessimistic Locking (비관적 잠금)과 비교:
- 비관적: 읽을 때부터 잠금 → 안전하지만 느림
- 낙관적: 저장할 때만 확인 → 빠르지만 충돌 처리 필요
```

**External Storage**
```
큰 BLOB 데이터를 DB 외부 파일로 저장하는 기능

@Attribute(.externalStorage)
var imageData: Data

DB에 저장되는 것:
imageData 컬럼 = NULL (또는 파일 참조)

실제 파일 위치:
.app_support/
└── .BabeLog_SUPPORT/
    └── _EXTERNAL_DATA/
        └── ABC123DEF456...  (해시값이 파일명)

장점:
- DB 파일 크기 감소 → 쿼리 성능 향상
- 이미지 직접 파일 접근 가능
```

**WAL (Write-Ahead Logging)**
```
트랜잭션 안전성을 위한 로깅 기법

기본 원리:
1. 변경사항을 먼저 로그 파일에 기록 (WAL)
2. 그다음 실제 DB 파일에 적용

WAL 없이:
COMMIT 중 정전 → DB 파일 손상 가능 (일부만 기록됨)

WAL 있으면:
1. WAL에 전체 변경 기록 완료
2. COMMIT 표시
3. DB에 적용 (체크포인트)

정전 시:
- WAL 로그를 읽어서 완료된 트랜잭션만 복구
- 불완전한 트랜잭션은 무시

파일 구조:
BabeLog.sqlite      (메인 DB)
BabeLog.sqlite-wal  (WAL 로그)
BabeLog.sqlite-shm  (공유 메모리)
```

**MVCC (Multi-Version Concurrency Control)**
```
동시 읽기/쓰기를 가능하게 하는 동시성 제어 기법

문제:
Reader A: SELECT * FROM babies (읽는 중)
Writer B: UPDATE babies SET name='민준' (쓰는 중)
→ A가 읽다가 B가 쓰면 충돌?

MVCC 해결책:
데이터의 여러 버전을 유지

┌─────────────────────────────────────┐
│ babies 테이블                        │
├─────────────────────────────────────┤
│ id=1, name='서연', version=1        │  ← 구버전
│ id=1, name='민준', version=2        │  ← 신버전
└─────────────────────────────────────┘

Reader A: 트랜잭션 시작 시점 = version 1
         → version 1의 데이터만 보임 ('서연')
         
Writer B: version 2 생성 ('민준')
         → A에게 영향 없음

→ Reader는 기다릴 필요 없고, Writer도 기다릴 필요 없음
→ 높은 동시성
```

---

## 10. 디자인 패턴 총정리

### GoF 패턴 (Gang of Four)

```
1994년 4명의 저자가 쓴 "Design Patterns" 책에 나온 23개 패턴

SwiftData에 사용된 패턴:

1. Virtual Proxy (구조 패턴)
   - Fault 객체
   - 실제 데이터 로딩을 지연

2. Repository (아키텍처 패턴 - DDD)
   - DatabaseClient
   - 데이터 접근 로직을 캡슐화

3. Unit of Work (아키텍처 패턴)
   - ModelContext
   - 변경 추적 및 일괄 커밋

4. Identity Map (아키텍처 패턴)
   - ModelContext 내부
   - 동일 레코드 = 동일 인스턴스 보장

5. Factory (생성 패턴)
   - ModelContainer
   - 복잡한 객체 생성을 캡슐화

6. Observer (행동 패턴)
   - @Observable 통합
   - 데이터 변경 시 UI 자동 업데이트
```

---

## 한 장 요약

```
SwiftData 구조:

┌────────────────────────────────────────────────────────────┐
│  @Model (매크로)                                            │
│  - 메타프로그래밍: 코드가 코드 생성                           │
│  - AOP: 모든 프로퍼티에 변경 추적 자동 삽입                    │
└────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────┐
│  ModelContext                                               │
│  - Unit of Work: 변경 추적, 일괄 커밋                        │
│  - Identity Map: 같은 레코드 = 같은 인스턴스                  │
│  - Dirty Checking: 변경된 것만 저장                          │
└────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────┐
│  @ModelActor                                                │
│  - Actor Model: 동시성 안전                                  │
│  - Serial Executor: 순차 처리                                │
│  - async/await: 협력적 스케줄링                              │
└────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────┐
│  Core Data / SQLite                                         │
│  - ORM: 객체 ↔ 테이블 매핑                                   │
│  - Faulting: 지연 로딩 (Virtual Proxy)                       │
│  - B-Tree Index: O(log n) 검색                              │
│  - ACID: 트랜잭션 안전성                                     │
│  - WAL: 크래시 복구                                          │
│  - MVCC: 동시 읽기/쓰기                                      │
└────────────────────────────────────────────────────────────┘
```
