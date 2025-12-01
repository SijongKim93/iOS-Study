import XCTest
import ComposableArchitecture
@testable import iOS_Study

@MainActor
final class TodoFeatureTests: XCTestCase {
    private var testDependencies: DependencyValues {
        var dependencies = DependencyValues()
        dependencies.todoClient = TodoClient(
            load: { [] },
            save: { _ in }
        )
        return dependencies
    }

    func testToggleFavoriteUpdatesStateAndStatistics() async {
        let baseDate = Date(timeIntervalSince1970: 0)
        let todo = Todo(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            title: "즐겨찾기 테스트",
            createdAt: baseDate
        )

        var initialState = TodoFeature.State()
        initialState.todos = [todo]
        initialState.filteredTodos = [todo]

        let store = TestStore(initialState: initialState) {
            TodoFeature()
        } withDependencies: { dependencies in
            dependencies = testDependencies
        }

        await store.send(.toggleFavorite(todo.id)) {
            $0.todos[0].isFavorite = true
        }

        await store.receive(.applyFiltersAndSort) {
            $0.filteredTodos = $0.todos
        }

        await store.receive(.saveTodos)
        await store.receive(.calculateStatistics)

        let expectedStats = TodoFeature.TodoStatistics(
            total: 1,
            completed: 0,
            active: 1,
            completionRate: 0,
            highPriorityActive: 0,
            favorites: 1,
            favoriteCompleted: 0
        )

        await store.receive(.statisticsCalculated(expectedStats)) {
            $0.statistics = expectedStats
        }

        await store.finish()
    }

    func testFavoritesFilterShowsOnlyFavorites() async {
        let baseDate = Date(timeIntervalSince1970: 100)
        let favoriteTodo = Todo(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            title: "즐겨찾기",
            createdAt: baseDate,
            isFavorite: true
        )
        let normalTodo = Todo(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            title: "일반",
            createdAt: baseDate.addingTimeInterval(10)
        )

        var initialState = TodoFeature.State()
        initialState.todos = [favoriteTodo, normalTodo]
        initialState.filteredTodos = [favoriteTodo, normalTodo]

        let store = TestStore(initialState: initialState) {
            TodoFeature()
        } withDependencies: { dependencies in
            dependencies = testDependencies
        }

        await store.send(.filterOptionChanged(.favorites)) {
            $0.filterOption = .favorites
        }

        await store.receive(.applyFiltersAndSort) {
            $0.filteredTodos = [$0.todos[0]]
        }

        await store.finish()
    }
}









