//
//  ContentView.swift
//  SimpleAsyncAwait
//
//  Created by Sriram Rama, Krishnan on 7/11/22.
//

import SwiftUI

struct Course: Decodable, Identifiable {
    let id, numberOfLessons: Int
    let name, link, imageUrl: String
}

class CourseViewModel: ObservableObject {
    @Published var isFetching = false
    @Published var courses: [Course]
    @Published var errorMessage: String
    
    init() {
        self.courses = []
        self.isFetching = false
        self.errorMessage = ""
    }
    
    @MainActor
    func fetchData() async {
        let apiUrl = "https://api.letsbuildthatapp.com/jsondecodable/courses"
        self.isFetching = true
        guard let url = URL(string: apiUrl) else {
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let resp = response as? HTTPURLResponse, resp.statusCode >= 300 {
                self.errorMessage = "Failed to fetch data from \(apiUrl)"
            }
            self.isFetching = false
            self.courses = try JSONDecoder().decode([Course].self, from: data)
        } catch {
            self.errorMessage = "Failed to fetch data from remote URL \(error)"
            print(self.errorMessage)
        }
    }
}


struct ContentView: View {
    @ObservedObject var cvm = CourseViewModel()
    
    private var refreshButton: some View {
        Button{
                Task.init {
                    cvm.courses.removeAll()
                    await cvm.fetchData()
                }
        } label: {
            Text("Refresh")
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                if self.cvm.isFetching {
                    ProgressView().padding()
                } else {
                    if cvm.errorMessage.isEmpty {
                        VStack {
                        ForEach(cvm.courses) { course in
                            Text(course.name).padding()
                            let imageUrl = URL(string: course.imageUrl)
                            AsyncImage(url: imageUrl) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .cornerRadius(4.0)
                                    .padding(5.0)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                        }
                    } else {
                        Text(cvm.errorMessage).padding()
                    }
                    
                }
            }
            .navigationBarItems(trailing: refreshButton)
            .navigationTitle("Courses")
                .task {
                    await cvm.fetchData()
                }
        }
    }
    
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
