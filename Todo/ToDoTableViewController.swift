//
//  ToDoTableViewController.swift
//  Todo
//
//  Created by Mark Meretzky on 3/31/19.
//  Copyright © 2019 New York University School of Professional Studies. All rights reserved.
//

import UIKit;
import AWSAppSync;

class ToDoTableViewController: UITableViewController {

    var appSyncClient: AWSAppSyncClient?;
    var todos: [Todo] = [Todo](); //The model is an array of Todo instances, initially empty.

    override func viewDidLoad() {
        super.viewDidLoad();
        
        //Initialize the appSyncClient property of the TodoTableViewController.
        guard let appDelegate: AppDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("TodoTableViewController couldn't find AppDelegate");
        }
        appSyncClient = appDelegate.appSyncClient;
        
        runQuery();
        subscribe();

        // Uncomment the following line to preserve selection between presentations
        // clearsSelectionOnViewWillAppear = false;

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        navigationItem.leftBarButtonItem = editButtonItem;
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todos.count;
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TodoTableViewCell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath) as! TodoTableViewCell;

        // Configure the cell ...
        let todo: Todo = todos[indexPath.row];
        cell.nameLabel.text = todo.name;
        cell.descriptionLabel.text = todo.description;
        cell.idLabel.text = todo.id;
        return cell;
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let todo: Todo = todos[indexPath.row];
            runDeleteMutation(todo);  //also removes the instance from todos, and removes the cell from the table
            //tableView.deleteRows(at: [indexPath], with: .fade);
        }   
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    // MARK: - Protocol UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 4 + 21 + 17 + 17 + 4;   //top and bottom margins, plus heights of the three UILabels
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation.
    // Arrive here when user presses + button or taps a cell.
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender);
        
        guard let indexPath: IndexPath = tableView.indexPathForSelectedRow else {
            //The user pressed the + button, so there is no information we need to
            //send on ahead to the ViewController.
            return;
        }
        
        // Get the new view controller using segue.destination.
        guard let viewController: ViewController = segue.destination as? ViewController else {
            fatalError("segue to unexpected view controller \(type(of: segue.destination))");
        }
        
        // Pass the selected object to the new view controller.
        viewController.todo = todos[indexPath.row];
    }
    
    @IBAction func unwind(unwindSegue: UIStoryboardSegue) {
        guard unwindSegue.identifier == "SaveSegue" else {
            return;   //Do nothing if user pressed Cancel.
        }
        
        guard let viewController: ViewController = unwindSegue.source as? ViewController else {
            fatalError("unwound from view controller of unexpected type \(type(of: unwindSegue.source))");
        }
        
        var todo: Todo = Todo(name: viewController.nameTextField.text ?? "", description: viewController.descriptionTextField.text ?? "");
        
        if let indexPath: IndexPath = tableView.indexPathForSelectedRow {
            todo.id = todos[indexPath.row].id;
            runUpdateMutation(todo);
        } else {
            runCreateMutation(todo);
        }
    }
    
    @IBAction func refreshButtonPressed(_ sender: UIBarButtonItem) {
        runQuery();
    }
    
    // MARK: - AWS
    
    //Download all the records from the server into todos property of this view controller.
    //Then reload this data into the cells of the table view.
    
    func runQuery() {
        print("runQuery()");
        
        appSyncClient?.fetch(query: ListTodosQuery(), cachePolicy: .returnCacheDataAndFetch) {(result:  GraphQLResult<ListTodosQuery.Data>?, error: Error?) in
            print("runQuery() closure");
            
            if let error: Error = error {
                print("runQuery(), error = \(error)");
                print("runQuery(), error.localizedDescription = \(error.localizedDescription)");
            }
            
            guard let result: GraphQLResult<ListTodosQuery.Data> = result else {
                fatalError("runQuery(), result = nil");
            }
            
            guard let data: ListTodosQuery.Data = result.data else {
                fatalError("runQuery(), result.data = nil");
            }
            
            guard let listTodos: ListTodosQuery.Data.ListTodo = data.listTodos else {
                fatalError("runQuery(), result.data.listTodos = nil");
            }
            
            guard let items: [ListTodosQuery.Data.ListTodo.Item?] = listTodos.items else {
                fatalError("runQuery(), result.data.listTodos.items = nil");
            }
            
            self.todos.removeAll();
            
            items.forEach {
                if let item: ListTodosQuery.Data.ListTodo.Item = $0 {
                    print("\(type(of: item)) \(item.id) \(item.name) \(item.description ?? "")");
                    let todo: Todo = Todo(id: item.id, name: item.name, description: item.description);
                    self.todos.append(todo);
                }
            }
            
            self.tableView.reloadData();
        }
    }
    
    //Upload a new record to the server, then call runQuery().
    //Called from unwind(unwindSegue:).

    func runCreateMutation(_ todo: Todo) {
        print("runCreateMutation(_:)");
        guard todos.count <= 100 else {
            print("Can't create more than 100 Todos.");
            return;
        }
        
        let mutationInput: CreateTodoInput = CreateTodoInput(name: todo.name, description: todo.description);
        let mutation: CreateTodoMutation = CreateTodoMutation(input: mutationInput);
        
        appSyncClient?.perform(mutation: mutation) {(result: GraphQLResult<CreateTodoMutation.Data>?, error: Error?) in
            print("runCreateMutation(_:) closure");
            
            if let error: AWSAppSyncClientError = error as? AWSAppSyncClientError {
                print("runCreateMutation(_:), error = \(error)");
                print("runCreateMutation(_:), error.localizedDescription = \(error.localizedDescription)");
            }
            
            guard let result: GraphQLResult<CreateTodoMutation.Data> = result else {
                print("runCreateMutation(_:), result = nil");
                return;
            }
            
            if let resultErrors: [GraphQLError] = result.errors {
                print("Error saving the item on server: \(resultErrors)");
            }
                
            print("runCreateMutation(_:), result = \(result)");
            self.runQuery();   //Runs after the mutation has finished.
        }
    }
    
    //Delete a record from the server, then call runQuery().
    
    func runDeleteMutation(_ todo: Todo) {
        print("runDeleteMutation(_:)");
        let mutationInput: DeleteTodoInput = DeleteTodoInput(id: todo.id);
        let mutation: DeleteTodoMutation = DeleteTodoMutation(input: mutationInput);
        
        appSyncClient?.perform(mutation: mutation) {(result: GraphQLResult<DeleteTodoMutation.Data>?, error: Error?) in
            print("runDeleteMutation(_:) closure");
            
            if let error: AWSAppSyncClientError = error as? AWSAppSyncClientError {
                print("runDeleteMutation(_:), error = \(error)");
                print("runDeleteMutation(_:), error.localizedDescription = \(error.localizedDescription)");
            }
            
            guard let result: GraphQLResult<DeleteTodoMutation.Data> = result else {
                print("runDeleteMutation(_:), result = nil");
                return;
            }
            
            if let resultErrors: [GraphQLError] = result.errors {
                print("runDeleteMutation(_:), result.errors = \(resultErrors)");
            }
            
            print("runDeleteMutation(_:), result = \(result)");
            self.runQuery();
        }
    }
    
    //Delete all records from the server, then call runQuery().
    
    func runDeleteAllMutation() {
        print("runDeleteAllMutation()");
        
        appSyncClient?.fetch(query: ListTodosQuery(), cachePolicy: .returnCacheDataAndFetch) {(result:  GraphQLResult<ListTodosQuery.Data>?, error: Error?) in
            print("runDeleteAllMutation() closure");
            
            if let error: AWSAppSyncClientError = error as? AWSAppSyncClientError {
                print("runDeleteAllMutation(_:), error = \(error)");
                print("runDeleteAllMutation(_:), error.localizedDescription = \(error.localizedDescription)");
            }
            
            guard let result: GraphQLResult<ListTodosQuery.Data> = result else {
                fatalError("runDeleteAllMutation(), result = nil");
            }
            
            if let resultErrors: [GraphQLError] = result.errors {
                print("runDeleteAllMutation(), result.errors = \(resultErrors)");
            }
            
            guard let data: ListTodosQuery.Data = result.data else {
                fatalError("runDeleteAllMutation(), result.data = nil");
            }
            
            guard let listTodos: ListTodosQuery.Data.ListTodo = data.listTodos else {
                fatalError("runDeleteAllMutation(), result.data.listTodos = nil");
            }
            
            guard let items: [ListTodosQuery.Data.ListTodo.Item?] = listTodos.items else {
                fatalError("runDeleteAllMutation(), result.data.listTodos.items = nil");
            }
            
            items.forEach {
                if let item: ListTodosQuery.Data.ListTodo.Item = $0 {
                    print("\(type(of: item)) \(item.id) \(item.name) \(item.description!)");
                    let todo: Todo = Todo(id: item.id, name: item.name, description: item.description!);
                    self.runDeleteMutation(todo);
                }
            }
            
            self.runQuery();
        }
    }
    
    func runUpdateMutation(_ todo: Todo) {
        print("runUpdateMutation(_:)");
        let mutationInput: UpdateTodoInput = UpdateTodoInput(id: todo.id, name: todo.name, description: todo.description);
        let mutation: UpdateTodoMutation = UpdateTodoMutation(input: mutationInput);
        
        appSyncClient?.perform(mutation: mutation) {(result: GraphQLResult<UpdateTodoMutation.Data>?, error: Error?) in
            print("runUpdateMutation(_:) closure");
            
            if let error: AWSAppSyncClientError = error as? AWSAppSyncClientError {
                print("runUpdateMutation(_:), error = \(error)");
                print("runUpdateMutation(_:), error.localizedDescription = \(error.localizedDescription)");
            }
            
            guard let result: GraphQLResult<UpdateTodoMutation.Data> = result else {
                print("runUpdateMutation(_:), result = nil");
                return;
            }
            
            if let resultErrors: [GraphQLError] = result.errors {
                print("runUpdateMutation(_:), result.errors = \(resultErrors)");
            }
            
            print("runUpdateMutation(_:), result = \(result)");
            self.runQuery();
        }
    }
    
    //Call the closure whenever a new record is added to the database.
    //The closure then calls runQuery().
    
    var discard: Cancellable?;
    
    func subscribe() {
        do {
            discard = try appSyncClient?.subscribe(subscription: OnCreateTodoSubscription(), resultHandler: {(result: GraphQLResult<OnCreateTodoSubscription.Data>?, transaction: ApolloStore.ReadWriteTransaction?, error: Error?) in
                
                print("subscribe() closure");
                
                if let error: Error = error {
                    print("subscribe(), error = \(error)");
                    print("subscribe(), error.localizedDescription = \(error.localizedDescription)");
                }
                
                guard let result: GraphQLResult<OnCreateTodoSubscription.Data> = result else {
                    print("subscribe() result = nil");
                    return;
                }
                
                guard let data: OnCreateTodoSubscription.Data = result.data else {
                    print("subscribe() result.data = nil");
                    return;
                }
                
                guard let onCreateTodo: OnCreateTodoSubscription.Data.OnCreateTodo = data.onCreateTodo else {
                    print("subscribe() result.data.onCreateTodo = nil");
                    return;
                }
                
                print("subscribe() \(onCreateTodo.name) \(onCreateTodo.description ?? "")");
                self.runQuery();
            });
        }
        
        catch {
            print("subscribe() threw exception, error = \(error)");
            print("subscribe(), threw error, error.localizedDescription = \(error.localizedDescription)");
        }
    }
    
}
