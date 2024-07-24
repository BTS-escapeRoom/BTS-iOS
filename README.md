# BTS-iOS

---
## 아키텍쳐 선정

본격적인 아키텍쳐 선정에 앞서,
2024년 7월 기준, 무려 11.9k 의 Stars를 받은 TCA에 대해 호기심이 생겨 알아보았다.

### [TCA Architecture(The Composable Architecture)](https://github.com/pointfreeco/swift-composable-architecture)
> iOS 및 macOS 애플리케이션 개발에서 상태 관리와 비즈니스 로직을 효율적으로 관리하기 위해 설계된 아키텍처(Point-Free 개발)

-> 단방향 아키텍쳐, Redux 패턴의 상태 관리 방식 (Reactorkit, Reswift...)

작년에 사이트 프로젝트로 진행했던, [쿠키](https://github.com/yi-sang/Cookie)의 아키텍쳐로 ReactorKit와 유사한 방식이었다.
첫 인상은, UIKit 환경에 두 개의 외부 라이브러리(RxSwift + ReactorKit)를 사용하는 것보단, SwiftUI에 TCA를 채용하는 것이 더욱 매력적으로 느껴졌다.
(TCA 공식 블로그에서 컴파일러의 안정성을 더욱 챙겼다는 이야기와 함께..)

**주요 구성 요소**
- State: 앱의 현재 상태를 나타내는 구조체. 앱의 모든 상태는 이곳에 정의.
- Action: 상태를 변경하는 이벤트 또는 사용자 동작을 정의. enum 타입으로 정의되며, 상태를 업데이트하는 다양한 액션을 포함.
- Environment: 외부 시스템이나 서비스와의 상호 작용을 정의. 예를 들어, API 호출, 데이터베이스 접근, 타이머 등을 포함할 수 있음.
- Reducer: 상태와 액션을 받아 새로운 상태를 반환하는 순수 함수. 모든 상태 변경 로직은 리듀서에서 처리.
- Store: 상태와 액션을 관리하는 객체. 뷰에서 스토어를 구독하여 상태 변화를 반영.

**주요 특징**
- Composable: 작은 모듈로 나누어 쉽게 조합할 수 있습니다. 이를 통해 복잡한 애플리케이션도 관리가 용이합니다.
- Testable: 상태와 액션이 명확히 분리되어 있기 때문에 유닛 테스트가 용이합니다.
- Consistency: 상태 관리가 중앙 집중화되어 있어 애플리케이션의 상태 변화가 일관성을 유지합니다.
- SwitfUI 통합: SwiftUI와 자연스럽게 통합되어 최신 iOS 개발 패러다임을 따릅니다.

**예제 코드**

Counter App

```swift
Copy code
import ComposableArchitecture

struct AppState: Equatable {
    var count = 0
}

enum AppAction: Equatable {
    case increment
    case decrement
}

struct AppEnvironment {}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, _ in
    switch action {
    case .increment:
        state.count += 1
        return .none
    case .decrement:
        state.count -= 1
        return .none
    }
}

struct AppView: View {
    let store: Store<AppState, AppAction>
    
    var body: some View {
        WithViewStore(self.store) { viewStore in
            VStack {
                Text("\(viewStore.count)")
                HStack {
                    Button("Increment") { viewStore.send(.increment) }
                    Button("Decrement") { viewStore.send(.decrement) }
                }
            }
        }
    }
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(
                initialState: AppState(),
                reducer: appReducer,
                environment: AppEnvironment()
            ))
        }
    }
}
```
AppState, AppAction, AppEnvironment를 정의하며,
appReducer를 통해 상태와 액션을 처리
AppView는 Store를 사용하여 상태를 구독하고 액션을 디스패치함.
-> TCA는 명확한 구조와 원칙을 바탕으로 앱의 상태 관리와 비즈니스 로직을 일관되게 유지할 수 있도록 도움

----

**MVVM 패턴과의 차이**
MVVM은 ViewModel에서 View에 대한 상태를 가지고는 있지만, Action을 따로 관리하지는 않는다.
하지만 Redux 관련 패턴은 (Action - State) : Store에서 관리함으로써 상태와 비즈니스 로직을 효율적으로 관리할 수 있다.


**SwiftUI와 MVVM과의 부적합성**
- 리액티브 바인딩과의 중복
 SwiftUI는 자체적으로 상태와 UI를 바인딩하는 메커니즘(예: @State, @Binding, @ObservedObject, @EnvironmentObject 등)을 제공
 MVVM 패턴에서 사용되는 ViewModel의 역할 중 하나는 상태를 관리하고 UI에 바인딩하는 것이지만, SwiftUI가 이미 이 부분을 효과적으로 다루기 때문에 ViewModel의 필요성이 낮음.
- ObservableObject와 State 관리
 SwiftUI는 ObservableObject와 @Published를 통해 상태 관리를 매우 직관적으로 처리할 수 있게 합니다. MVVM에서 ViewModel은 데이터 로딩 및 상태 변화를 처리하는데, SwiftUI는 이러한 기능을 ObservableObject와 Combine을 통해 내장 지원합니다. 따라서 MVVM을 적용할 때 ViewModel과 SwiftUI의 상태 관리가 중복되거나 충돌할 수 있음.
- 간단한 구조
 SwiftUI는 매우 선언적인 UI 구성 방식을 가지고 있어, 복잡한 로직을 View와 ViewModel로 나누지 않고도 간단하게 구현할 수 있다. 즉, MVVM 패턴이 추가적인 복잡성을 초래할 수 있습니다.
- 양방향 Flow
 ViewModel이 View와 Model에 의하여 변경된다는 점. 어느 곳에서 View의 데이터들이 업데이트 되는 것인지 확신할 수 없음.

-> 단방향 Flow의 장점, SwiftUI - MVVM 과의 부적합성에 대한 공감, 유닛 테스트 도전, 호기심으로 TCA 아키텍쳐를 사용해보기로 결정!
