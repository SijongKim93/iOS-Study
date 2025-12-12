//
//  ClosuresExampleView.swift
//  iOS-Study
//
//  Created by duse on 12/12/25.
//

import SwiftUI

// MARK: - 클로저를 사용하는 예제 클래스

class ClosureExample {

    // MARK: - 1. Non-Escaping 클로저 (기본)
    // 함수가 반환되기 전에 클로저가 실행됩니다
    func performNonEscaping(completion: () -> Void) {
        print("⏰ Non-Escaping: 함수 시작")
        completion()  // 함수 내에서 바로 실행
        print("✅ Non-Escaping: 함수 종료")
    }

    // MARK: - 2. Escaping 클로저
    // 함수가 반환된 후에도 클로저가 실행될 수 있습니다
    func performEscaping(completion: @escaping () -> Void) {
        print("⏰ Escaping: 함수 시작")

        // 비동기로 2초 후 실행
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion()  // 함수가 종료된 후 실행
        }

        print("✅ Escaping: 함수 종료 (클로저는 아직 실행 안됨)")
    }

    // MARK: - 3. 실제 사용 예제: 데이터 저장
    private var savedClosure: (() -> Void)?

    // 클로저를 저장하려면 @escaping 필요
    func saveClosure(closure: @escaping () -> Void) {
        savedClosure = closure
    }

    func executeSavedClosure() {
        savedClosure?()
    }
}

// MARK: - 네트워크 요청 시뮬레이션

class NetworkService {

    // 비동기 작업에서는 항상 @escaping 클로저 사용
    func fetchData(completion: @escaping (String) -> Void) {
        print("🌐 네트워크 요청 시작...")

        // 2초 후 데이터 반환 시뮬레이션
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let data = "서버에서 받은 데이터"
            completion(data)
        }

        print("📤 요청 전송 완료 (응답 대기 중...)")
    }
}

// MARK: - SwiftUI View

struct ClosuresExampleView: View {
    @State private var nonEscapingLog: [String] = []
    @State private var escapingLog: [String] = []
    @State private var networkLog: [String] = []
    @State private var savedClosureLog: [String] = []
    @State private var isLoading = false

    let closureExample = ClosureExample()
    let networkService = NetworkService()

    var body: some View {
        List {
            // MARK: - Non-Escaping 예제
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        nonEscapingLog.removeAll()

                        nonEscapingLog.append("1️⃣ 버튼 클릭")

                        closureExample.performNonEscaping {
                            nonEscapingLog.append("2️⃣ 클로저 실행됨")
                        }

                        nonEscapingLog.append("3️⃣ 버튼 핸들러 종료")

                    } label: {
                        Label("Non-Escaping 실행", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if !nonEscapingLog.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("실행 순서:")
                                .font(.caption)
                                .fontWeight(.semibold)

                            ForEach(nonEscapingLog.indices, id: \.self) { index in
                                Text(nonEscapingLog[index])
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                }

                Text("클로저가 함수 내에서 즉시 실행됩니다. 함수가 반환되기 전에 클로저가 완료됩니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            } header: {
                Text("1. Non-Escaping 클로저")
            } footer: {
                Text("기본값이며, @escaping 키워드가 필요 없습니다.")
            }

            // MARK: - Escaping 예제
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        escapingLog.removeAll()

                        escapingLog.append("1️⃣ 버튼 클릭")

                        closureExample.performEscaping {
                            escapingLog.append("3️⃣ 클로저 실행됨 (2초 후)")
                        }

                        escapingLog.append("2️⃣ 버튼 핸들러 종료")

                    } label: {
                        Label("Escaping 실행", systemImage: "clock.arrow.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)

                    if !escapingLog.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("실행 순서:")
                                .font(.caption)
                                .fontWeight(.semibold)

                            ForEach(escapingLog.indices, id: \.self) { index in
                                Text(escapingLog[index])
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                }

                Text("클로저가 함수가 반환된 후에 실행됩니다. 비동기 작업에 필수입니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            } header: {
                Text("2. Escaping 클로저 (@escaping)")
            } footer: {
                Text("함수가 종료된 후에도 클로저가 실행되므로 @escaping 키워드가 필요합니다.")
            }

            // MARK: - 네트워크 요청 예제
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        networkLog.removeAll()
                        isLoading = true

                        networkLog.append("📱 요청 시작")

                        networkService.fetchData { data in
                            networkLog.append("📦 데이터 수신: \(data)")
                            isLoading = false
                        }

                        networkLog.append("⏳ 다른 작업 가능")

                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Label("네트워크 요청", systemImage: "network")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(isLoading)

                    if !networkLog.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(networkLog.indices, id: \.self) { index in
                                Text(networkLog[index])
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                }

                Text("실제 네트워크 요청처럼 비동기로 데이터를 받습니다. completion 핸들러는 반드시 @escaping이어야 합니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            } header: {
                Text("3. 실전 예제: 네트워크 요청")
            } footer: {
                Text("API 호출, 데이터베이스 쿼리 등 모든 비동기 작업은 escaping 클로저를 사용합니다.")
            }

            // MARK: - 클로저 저장 예제
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        savedClosureLog.removeAll()
                        savedClosureLog.append("💾 클로저 저장됨")

                        closureExample.saveClosure {
                            savedClosureLog.append("🎉 저장된 클로저 실행!")
                        }
                    } label: {
                        Label("클로저 저장", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        closureExample.executeSavedClosure()
                    } label: {
                        Label("저장된 클로저 실행", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)

                    if !savedClosureLog.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(savedClosureLog.indices, id: \.self) { index in
                                Text(savedClosureLog[index])
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                }

                Text("클로저를 변수에 저장하려면 @escaping이 필요합니다. 함수가 종료된 후에도 클로저가 메모리에 유지되기 때문입니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            } header: {
                Text("4. 클로저 저장")
            } footer: {
                Text("클로저를 프로퍼티에 저장하는 경우 함수 스코프를 벗어나므로 @escaping이 필요합니다.")
            }

            // MARK: - 요약
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    summaryRow(
                        title: "Non-Escaping",
                        icon: "checkmark.circle.fill",
                        color: .blue,
                        description: "함수 내에서 즉시 실행되는 클로저"
                    )

                    Divider()

                    summaryRow(
                        title: "Escaping",
                        icon: "arrow.up.right.circle.fill",
                        color: .orange,
                        description: "함수 종료 후 실행될 수 있는 클로저"
                    )

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text("언제 @escaping을 사용하나요?")
                                .fontWeight(.semibold)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("• 비동기 작업 (네트워크, 타이머)")
                            Text("• 클로저를 저장하는 경우")
                            Text("• 다른 스레드에서 실행")
                            Text("• 함수 종료 후 실행")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 28)
                    }
                }
                .padding(.vertical, 4)

            } header: {
                Text("개념 요약")
            }
        }
        .navigationTitle("Closures: Escaping")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func summaryRow(title: String, icon: String, color: Color, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ClosuresExampleView()
    }
}
