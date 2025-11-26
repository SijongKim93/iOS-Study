//
//  GenericsExampleView.swift
//  iOS-Study
//
//  Created by duse on 11/26/25.
//

import SwiftUI

// MARK: - 1. 기본 제네릭 함수
func swapValues<T>(_ a: inout T, _ b: inout T) {
    let temp = a
    a = b
    b = temp
}

// MARK: - 2. 제네릭 Stack 구조체
struct Stack<Element> {
    private var items: [Element] = []

    mutating func push(_ item: Element) {
        items.append(item)
    }

    mutating func pop() -> Element? {
        return items.isEmpty ? nil : items.removeLast()
    }

    func peek() -> Element? {
        return items.last
    }

    var count: Int {
        return items.count
    }

    var isEmpty: Bool {
        return items.isEmpty
    }

    var allItems: [Element] {
        return items
    }
}

// MARK: - 3. 타입 제약이 있는 제네릭
func findIndex<T: Equatable>(of valueToFind: T, in array: [T]) -> Int? {
    for (index, value) in array.enumerated() {
        if value == valueToFind {
            return index
        }
    }
    return nil
}

// MARK: - 4. 제네릭 프로토콜 (Associated Type)
protocol Container {
    associatedtype Item
    mutating func append(_ item: Item)
    var count: Int { get }
    subscript(i: Int) -> Item { get }
}

// Stack을 Container 프로토콜을 준수하도록 확장
extension Stack: Container {
    mutating func append(_ item: Element) {
        self.push(item)
    }

    subscript(i: Int) -> Element {
        return allItems[i]
    }
}

// MARK: - 5. Where 절을 사용한 제네릭
func allItemsMatch<C1: Container, C2: Container>(_ container1: C1, _ container2: C2) -> Bool
    where C1.Item == C2.Item, C1.Item: Equatable {

    if container1.count != container2.count {
        return false
    }

    for i in 0..<container1.count {
        if container1[i] != container2[i] {
            return false
        }
    }

    return true
}

// MARK: - SwiftUI View
struct GenericsExampleView: View {
    @State private var intStack = Stack<Int>()
    @State private var stringStack = Stack<String>()
    @State private var newIntValue = ""
    @State private var newStringValue = ""
    @State private var swapA = 10
    @State private var swapB = 20
    @State private var searchArray = [1, 2, 3, 4, 5]
    @State private var searchValue = ""
    @State private var searchResult: String = ""

    var body: some View {
        List {
            // 1. Swap 예제
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("A: \(swapA)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("B: \(swapB)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                .padding(.vertical, 8)

                Button {
                    var a = swapA
                    var b = swapB
                    swapValues(&a, &b)
                    swapA = a
                    swapB = b
                } label: {
                    Label("Swap Values", systemImage: "arrow.left.arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Text("제네릭 함수로 타입에 관계없이 두 값을 교환합니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("1. Generic Function")
            }

            // 2. Int Stack 예제
            Section {
                HStack {
                    TextField("숫자 입력", text: $newIntValue)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)

                    Button {
                        if let value = Int(newIntValue) {
                            intStack.push(value)
                            newIntValue = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newIntValue.isEmpty)
                }

                if !intStack.isEmpty {
                    HStack {
                        Text("Stack 상태:")
                            .fontWeight(.medium)
                        Text(intStack.allItems.map { String($0) }.joined(separator: " → "))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Button {
                            _ = intStack.pop()
                        } label: {
                            Label("Pop", systemImage: "minus.circle")
                        }
                        .buttonStyle(.bordered)

                        if let top = intStack.peek() {
                            Text("Top: \(top)")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                Text("제네릭 Stack<Int> 자료구조 예제입니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("2. Generic Stack<Int>")
            }

            // 3. String Stack 예제
            Section {
                HStack {
                    TextField("문자열 입력", text: $newStringValue)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        if !newStringValue.isEmpty {
                            stringStack.push(newStringValue)
                            newStringValue = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newStringValue.isEmpty)
                }

                if !stringStack.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Stack 상태:")
                            .fontWeight(.medium)
                        ForEach(stringStack.allItems.indices, id: \.self) { index in
                            Text("[\(index)] \(stringStack.allItems[index])")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        _ = stringStack.pop()
                    } label: {
                        Label("Pop", systemImage: "minus.circle")
                    }
                    .buttonStyle(.bordered)
                }

                Text("같은 제네릭 Stack을 String 타입으로 재사용합니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("3. Generic Stack<String>")
            }

            // 4. Type Constraint 예제
            Section {
                HStack {
                    TextField("검색할 숫자", text: $searchValue)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)

                    Button {
                        if let value = Int(searchValue) {
                            if let index = findIndex(of: value, in: searchArray) {
                                searchResult = "인덱스 \(index)에서 발견!"
                            } else {
                                searchResult = "찾을 수 없습니다."
                            }
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .disabled(searchValue.isEmpty)
                }

                Text("배열: \(searchArray.map { String($0) }.joined(separator: ", "))")
                    .foregroundStyle(.secondary)

                if !searchResult.isEmpty {
                    Text(searchResult)
                        .foregroundStyle(.blue)
                        .fontWeight(.medium)
                }

                Text("Equatable 프로토콜 제약을 사용한 제네릭 검색 함수입니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("4. Type Constraint (Equatable)")
            }

            // 5. Associated Type 설명
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(.blue)
                        Text("Container Protocol")
                            .fontWeight(.semibold)
                    }

                    Text("Stack 구조체는 Container 프로토콜을 준수합니다.")
                        .font(.subheadline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("• associatedtype Item")
                        Text("• func append(_ item: Item)")
                        Text("• var count: Int")
                        Text("• subscript(i: Int) -> Item")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading)
                }
                .padding(.vertical, 4)

                Text("Associated Type을 사용하여 프로토콜에서 제네릭을 정의합니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("5. Associated Type")
            }
        }
        .navigationTitle("Generics 예제")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GenericsExampleView()
    }
}
