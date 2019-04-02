//
//  ViewController.swift
//  Todo
//
//  Created by Mark Meretzky on 3/31/19.
//  Copyright © 2019 New York University School of Professional Studies. All rights reserved.
//

import UIKit;

class ViewController: UIViewController {
    
    var todo: Todo?;
    @IBOutlet weak var nameTextField: UITextField!;
    @IBOutlet weak var descriptionTextField: UITextField!;
    
    // Arrive here when user presses the + button or taps a cell in the TodoTableViewController.
    
    override func viewDidLoad() {
        super.viewDidLoad();

        // Do any additional setup after loading the view.
        if let todo: Todo = todo {
            navigationItem.title = "Update To Do";
            nameTextField.text = todo.name;
            descriptionTextField.text = todo.description;
        } else {
            navigationItem.title = "New To Do";
        }
    }
    
    // Arrive here when user presses Save or Cancel.
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender);

        guard segue.identifier == "SaveSegue" else {
            //User pressed Cancel, so no information needs to be transmitted
            //back to the TodoTableViewController.
            return;
        }
        
        todo = Todo(
            name: nameTextField.text ?? "",
            description: descriptionTextField.text ?? ""
        );
    }

}
