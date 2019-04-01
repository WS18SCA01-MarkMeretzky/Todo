//
//  TodoTableViewCell.swift
//  Todo
//
//  Created by Mark Meretzky on 3/31/19.
//  Copyright © 2019 New York University School of Professional Studies. All rights reserved.
//

import UIKit;

//See pp. 626-630 for creating a subclass of UITableViewCell.
//Class UITableViewCell already has a property named description.

class TodoTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!;
    @IBOutlet weak var descriptionLabel: UILabel!;
    @IBOutlet weak var idLabel: UILabel!;
    
    override func awakeFromNib() {
        super.awakeFromNib();
        // Initialization code.
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated);

        // Configure the view for the selected state.
    }

}
