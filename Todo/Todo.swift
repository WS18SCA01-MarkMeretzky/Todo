//
//  Todo.swift
//  Todo
//
//  Created by Mark Meretzky on 3/31/19.
//  Copyright © 2019 New York University School of Professional Studies. All rights reserved.
//

import Foundation;

struct Todo {
    var id: String;   //assigned by AWS, not by us
    var name: String;
    var description: String?;
    
    init(id: String = "", name: String, description: String?) {
        self.id = id;
        self.name = name;
        self.description = description;
    }
}

