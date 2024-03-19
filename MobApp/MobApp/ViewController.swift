//
//  ViewController.swift
//  MobApp
//
//  Created by SHRENIKA SOMA on 3/18/24.
//
import UIKit

struct Item: Codable {
    let id: Int
    let listId: Int
    let name: String?
}

class ViewController: UIViewController, UITableViewDataSource {

    var items: [Item] = []
    var groupedItems: [(listId: Int, itemList: [Item])] = []

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        fetchData()
    }

    func fetchData() {
        guard let url = URL(string: "https://fetch-hiring.s3.amazonaws.com/hiring.json") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching data: \(error)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                let decoder = JSONDecoder()
                self.items = try decoder.decode([Item].self, from: data)
                self.filterAndSortItems()
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                print("Error decoding data: \(error)")
            }
        }.resume()
    }

    func filterAndSortItems() {
        // Filter out items with blank or null names
        let filteredItems = items.filter { $0.name != nil && !$0.name!.isEmpty }

        // Group items by listId
        let groupedDictionary = Dictionary(grouping: filteredItems, by: { $0.listId })

        // Sort grouped items by listId then by name
        groupedItems = groupedDictionary.sorted { $0.key < $1.key }.map { ($0.key, $0.value.sorted { $0.name! < $1.name! }) }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return groupedItems.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupedItems[section].itemList.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "List ID: \(groupedItems[section].listId)"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = groupedItems[indexPath.section].itemList[indexPath.row]
        cell.textLabel?.text = item.name
        return cell
    }
}
