## ActivityIndicator
ActivityIndicator is a lightweight Swift library for tracking the activity states of Combine publishers. It helps manage and observe loading states efficiently, making it easier to handle activity indicators in your app.

## Features
1. Track activity states of Combine publishers.
2. Easily integrate with any Combine-based code.
3. Lightweight and easy to use.

## Usage
### SwiftUI Example

using ActivityIndicator in your viewModel 

```shell
import SwiftUI
import Combine

class MyViewModel: ObservableObject {
    @Published var isLoading = false
    private var cancellables = Set<AnyCancellable>()
    private let activityIndicator = ActivityIndicator()

    init() {
        bindActivityIndicator()
    }

    private func bindActivityIndicator() {
        activityIndicator.isActive
            .receive(on: RunLoop.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
    }
    
         // MARK: -  Normal use
    func fetchData() {
        let publisher = URLSession.shared.dataTaskPublisher(for: URL(string: "https://jsonplaceholder.typicode.com/posts")!)
        
        publisher
            .trackActivity(activityIndicator)
            .sink(receiveCompletion: { completion in
                // Handle completion
            }, receiveValue: { data, response in
                // Handle data
            })
            .store(in: &cancellables)
    }


        // MARK: -  Sequential use
    func fetchData1() {
        let publisher = URLSession.shared.dataTaskPublisher(for: URL(string: "https://jsonplaceholder.typicode.com/posts")!)
        
        publisher
            .trackActivitySequential(activityIndicator)
            .sink(receiveCompletion: { completion in
                // Handle completion
            }, receiveValue: { [weak self] (data, response) in
                // Handle data
                self?.fetchData2()
            })
            .store(in: &cancellables)
    }
    
    func fetchData2() {
        let publisher = URLSession.shared.dataTaskPublisher(for: URL(string: "https://jsonplaceholder.typicode.com/posts")!)
        
        publisher
            .trackActivitySequential(activityIndicator)
            .sink(receiveCompletion: { completion in
                // Handle completion
            }, receiveValue: { [weak self] (data, response) in
                // Handle data
                self?.fetchData3()
            })
            .store(in: &cancellables)
    }
    
    func fetchData3() {
        let publisher = URLSession.shared.dataTaskPublisher(for: URL(string: "https://jsonplaceholder.typicode.com/posts")!)
        
        publisher
            .trackActivitySequential(activityIndicator, isLastOne: true)// isLastOne = true to stop indicator when finished processing or error
            .sink(receiveCompletion: { completion in
                // Handle completion
            }, receiveValue: { (data, response) in
                // Handle data
            })
            .store(in: &cancellables)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = MyViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading...")
            } else {
                Text("Data Loaded")
            }
            
            Button("Fetch Data") {
                viewModel.fetchData()
            }
        }
    }
}

```


### SharedManager Example

For a more complete usage example, you can create an ActivityIndicatorManager to manage the activity indicator globally.


```shell
import Foundation
import UIKit
import Combine

public class ActivityIndicatorManager {
    public static let shared = ActivityIndicatorManager()

    let activityIndicator = ActivityIndicator()
    private var cancellable = Set<AnyCancellable>()

    private init() {
        manageBinding()
    }

    private func manageBinding() {
        activityIndicator.isActive
            .receive(on: RunLoop.main)
            .sink { isActive in
                UIApplication.shared.showLoader(isActive)
            }
            .store(in: &cancellable)
    }
}
```

## Additional information
Provided By Mohammed Essam
