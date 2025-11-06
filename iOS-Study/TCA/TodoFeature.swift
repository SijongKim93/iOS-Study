//
//  TodoFeature.swift
//  iOS-Study
//
//  Created by duse on 10/23/25.
//

import Foundation
import ComposableArchitecture

// MARK: - Todo 모델
struct Todo: Equatable, Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var priority: Priority
    var createdAt: Date
    var completedAt: Date?
    var dueDate: Date?
    var notes: String
    
    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        priority: Priority = .medium,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        dueDate: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.priority = priority
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.notes = notes
    }
}

enum Priority: String, CaseIterable, Equatable, Codable {
    case low = "낮음"
    case medium = "보통"
    case high = "높음"
    
    var order: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
}

enum FilterOption: String, CaseIterable, Equatable {
    case all = "전체"
    case active = "미완료"
    case completed = "완료"
}

enum SortOption: String, CaseIterable, Equatable {
    case createdAt = "생성일"
    case priority = "우선순위"
    case dueDate = "마감일"
    case title = "제목"
}

// MARK: - TodoFeature
@Reducer
struct TodoFeature {
    
    @ObservableState
    struct State: Equatable {
        var todos: [Todo] = []
        var filteredTodos: [Todo] = []
        var searchText: String = ""
        var filterOption: FilterOption = .all
        var sortOption: SortOption = .createdAt
        var isAscending: Bool = true
        var isLoading: Bool = false
        var errorMessage: String?
        var showAddTodo: Bool = false
        var editingTodo: Todo?
        var newTodoTitle: String = ""
        var newTodoPriority: Priority = .medium
        var newTodoDueDate: Date?
        var newTodoNotes: String = ""
        var statistics: TodoStatistics?
    }
    
    struct TodoStatistics: Equatable {
        var total: Int
        var completed: Int
        var active: Int
        var completionRate: Double
        var highPriorityActive: Int
    }
    
    enum Action {
        case onAppear
        case loadTodos
        case todosLoaded([Todo])
        case saveTodos
        case addTodoButtonTapped
        case cancelAddTodo
        case newTodoTitleChanged(String)
        case newTodoPriorityChanged(Priority)
        case newTodoDueDateChanged(Date?)
        case newTodoNotesChanged(String)
        case saveNewTodo
        case deleteTodo(UUID)
        case toggleTodo(UUID)
        case editTodo(UUID)
        case updateTodoTitle(UUID, String)
        case updateTodoPriority(UUID, Priority)
        case updateTodoDueDate(UUID, Date?)
        case updateTodoNotes(UUID, String)
        case cancelEditTodo
        case saveEditTodo
        case searchTextChanged(String)
        case filterOptionChanged(FilterOption)
        case sortOptionChanged(SortOption)
        case toggleSortOrder
        case clearCompleted
        case markAllAsCompleted
        case markAllAsActive
        case calculateStatistics
        case statisticsCalculated(TodoStatistics)
        case applyFiltersAndSort
        case clearError
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            @Dependency(\.todoClient) var todoClient
            
            switch action {
            case .onAppear:
                return .send(.loadTodos)
                
            case .loadTodos:
                state.isLoading = true
                return .run { send in
                    let todos = try await todoClient.load()
                    await send(.todosLoaded(todos))
                }
                
            case let .todosLoaded(todos):
                state.isLoading = false
                state.todos = todos
                return .merge([
                    .send(.applyFiltersAndSort),
                    .send(.calculateStatistics)
                ])
                
            case .saveTodos:
                return .run { [todos = state.todos] send in
                    try await todoClient.save(todos)
                }
                
            case .addTodoButtonTapped:
                state.showAddTodo = true
                state.newTodoTitle = ""
                state.newTodoPriority = .medium
                state.newTodoDueDate = nil
                state.newTodoNotes = ""
                return .none
                
            case .cancelAddTodo:
                state.showAddTodo = false
                state.newTodoTitle = ""
                state.newTodoPriority = .medium
                state.newTodoDueDate = nil
                state.newTodoNotes = ""
                return .none
                
            case let .newTodoTitleChanged(text):
                state.newTodoTitle = text
                return .none
                
            case let .newTodoPriorityChanged(priority):
                state.newTodoPriority = priority
                return .none
                
            case let .newTodoDueDateChanged(date):
                state.newTodoDueDate = date
                return .none
                
            case let .newTodoNotesChanged(notes):
                state.newTodoNotes = notes
                return .none
                
            case .saveNewTodo:
                guard !state.newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
                    state.errorMessage = "제목을 입력해주세요"
                    return .none
                }
                
                let newTodo = Todo(
                    title: state.newTodoTitle,
                    priority: state.newTodoPriority,
                    dueDate: state.newTodoDueDate,
                    notes: state.newTodoNotes
                )
                state.todos.append(newTodo)
                state.showAddTodo = false
                state.newTodoTitle = ""
                state.newTodoPriority = .medium
                state.newTodoDueDate = nil
                state.newTodoNotes = ""
                
                return .merge([
                    .send(.applyFiltersAndSort),
                    .send(.saveTodos),
                    .send(.calculateStatistics)
                ])
                
            case let .deleteTodo(id):
                state.todos.removeAll { $0.id == id }
                return .merge([
                    .send(.applyFiltersAndSort),
                    .send(.saveTodos),
                    .send(.calculateStatistics)
                ])
                
            case let .toggleTodo(id):
                if let index = state.todos.firstIndex(where: { $0.id == id }) {
                    state.todos[index].isCompleted.toggle()
                    if state.todos[index].isCompleted {
                        state.todos[index].completedAt = Date()
                    } else {
                        state.todos[index].completedAt = nil
                    }
                }
                return .merge([
                    .send(.applyFiltersAndSort),
                    .send(.saveTodos),
                    .send(.calculateStatistics)
                ])
                
            case let .editTodo(id):
                if let todo = state.todos.first(where: { $0.id == id }) {
                    state.editingTodo = todo
                    state.newTodoTitle = todo.title
                    state.newTodoPriority = todo.priority
                    state.newTodoDueDate = todo.dueDate
                    state.newTodoNotes = todo.notes
                }
                return .none
                
            case let .updateTodoTitle(id, title):
                if let index = state.todos.firstIndex(where: { $0.id == id }) {
                    state.todos[index].title = title
                }
                return .none
                
            case let .updateTodoPriority(id, priority):
                if let index = state.todos.firstIndex(where: { $0.id == id }) {
                    state.todos[index].priority = priority
                }
                return .send(.applyFiltersAndSort)
                
            case let .updateTodoDueDate(id, date):
                if let index = state.todos.firstIndex(where: { $0.id == id }) {
                    state.todos[index].dueDate = date
                }
                return .send(.applyFiltersAndSort)
                
            case let .updateTodoNotes(id, notes):
                if let index = state.todos.firstIndex(where: { $0.id == id }) {
                    state.todos[index].notes = notes
                }
                return .none
                
            case .cancelEditTodo:
                state.editingTodo = nil
                state.newTodoTitle = ""
                state.newTodoPriority = .medium
                state.newTodoDueDate = nil
                state.newTodoNotes = ""
                return .none
                
            case .saveEditTodo:
                guard let editingTodo = state.editingTodo,
                      !state.newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
                    state.errorMessage = "제목을 입력해주세요"
                    return .none
                }
                
                if let index = state.todos.firstIndex(where: { $0.id == editingTodo.id }) {
                    state.todos[index].title = state.newTodoTitle
                    state.todos[index].priority = state.newTodoPriority
                    state.todos[index].dueDate = state.newTodoDueDate
                    state.todos[index].notes = state.newTodoNotes
                }
                
                state.editingTodo = nil
                state.newTodoTitle = ""
                state.newTodoPriority = .medium
                state.newTodoDueDate = nil
                state.newTodoNotes = ""
                
                return .merge([
                    .send(.applyFiltersAndSort),
                    .send(.saveTodos),
                    .send(.calculateStatistics)
                ])
                
            case let .searchTextChanged(text):
                state.searchText = text
                return .send(.applyFiltersAndSort)
                
            case let .filterOptionChanged(option):
                state.filterOption = option
                return .send(.applyFiltersAndSort)
                
            case let .sortOptionChanged(option):
                state.sortOption = option
                return .send(.applyFiltersAndSort)
                
            case .toggleSortOrder:
                state.isAscending.toggle()
                return .send(.applyFiltersAndSort)
                
            case .applyFiltersAndSort:
                var filtered = state.todos
                
                // 필터링
                switch state.filterOption {
                case .all:
                    break
                case .active:
                    filtered = filtered.filter { !$0.isCompleted }
                case .completed:
                    filtered = filtered.filter { $0.isCompleted }
                }
                
                // 검색
                if !state.searchText.isEmpty {
                    filtered = filtered.filter { todo in
                        todo.title.localizedCaseInsensitiveContains(state.searchText) ||
                        todo.notes.localizedCaseInsensitiveContains(state.searchText)
                    }
                }
                
                // 정렬
                filtered.sort { todo1, todo2 in
                    let comparison: Bool
                    switch state.sortOption {
                    case .createdAt:
                        comparison = todo1.createdAt < todo2.createdAt
                    case .priority:
                        comparison = todo1.priority.order < todo2.priority.order
                    case .dueDate:
                        let date1 = todo1.dueDate ?? Date.distantFuture
                        let date2 = todo2.dueDate ?? Date.distantFuture
                        comparison = date1 < date2
                    case .title:
                        comparison = todo1.title < todo2.title
                    }
                    return state.isAscending ? comparison : !comparison
                }
                
                state.filteredTodos = filtered
                return .none
                
            case .clearCompleted:
                state.todos.removeAll { $0.isCompleted }
                return .merge([
                    .send(.applyFiltersAndSort),
                    .send(.saveTodos),
                    .send(.calculateStatistics)
                ])
                
            case .markAllAsCompleted:
                for index in state.todos.indices where !state.todos[index].isCompleted {
                    state.todos[index].isCompleted = true
                    state.todos[index].completedAt = Date()
                }
                return .merge([
                    .send(.applyFiltersAndSort),
                    .send(.saveTodos),
                    .send(.calculateStatistics)
                ])
                
            case .markAllAsActive:
                for index in state.todos.indices where state.todos[index].isCompleted {
                    state.todos[index].isCompleted = false
                    state.todos[index].completedAt = nil
                }
                return .merge([
                    .send(.applyFiltersAndSort),
                    .send(.saveTodos),
                    .send(.calculateStatistics)
                ])
                
            case .calculateStatistics:
                let total = state.todos.count
                let completed = state.todos.filter { $0.isCompleted }.count
                let active = total - completed
                let completionRate = total > 0 ? Double(completed) / Double(total) * 100 : 0
                let highPriorityActive = state.todos.filter { !$0.isCompleted && $0.priority == .high }.count
                
                let stats = TodoStatistics(
                    total: total,
                    completed: completed,
                    active: active,
                    completionRate: completionRate,
                    highPriorityActive: highPriorityActive
                )
                return .send(.statisticsCalculated(stats))
                
            case let .statisticsCalculated(stats):
                state.statistics = stats
                return .none
                
            case .clearError:
                state.errorMessage = nil
                return .none
            }
        }
    }
}

// MARK: - TodoClient
struct TodoClient {
    var load: () async throws -> [Todo]
    var save: ([Todo]) async throws -> Void
}

extension TodoClient: DependencyKey {
    static var liveValue: TodoClient {
        TodoClient(
            load: {
                try await Task.sleep(for: .milliseconds(200))
                if let data = UserDefaults.standard.data(forKey: "todos"),
                   let todos = try? JSONDecoder().decode([Todo].self, from: data) {
                    return todos
                }
                return []
            },
            save: { todos in
                try await Task.sleep(for: .milliseconds(200))
                if let data = try? JSONEncoder().encode(todos) {
                    UserDefaults.standard.set(data, forKey: "todos")
                }
            }
        )
    }
    
    static var testValue: TodoClient {
        TodoClient(
            load: { [] },
            save: { _ in }
        )
    }
}

extension DependencyValues {
    var todoClient: TodoClient {
        get { self[TodoClient.self] }
        set { self[TodoClient.self] = newValue }
    }
}

