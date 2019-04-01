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
    
    override func viewDidLoad() {
        super.viewDidLoad();

        // Do any additional setup after loading the view.
        if let todo: Todo = todo {
            nameTextField.text = todo.name;
            descriptionTextField.text = todo.description;
        }
    }
}
