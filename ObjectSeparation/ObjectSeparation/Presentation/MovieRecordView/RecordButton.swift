//
//  RecordButton.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/19.
//

import UIKit

final class RecordButton: UIButton {
    
    private var isToggled: Bool {
        didSet {
            if isToggled {
                setImage(Constants.RecordButtonImage.stopRecord, for: .normal)
            } else {
                setImage(Constants.RecordButtonImage.startRecord, for: .normal)
            }
        }
    }
    
    override init(frame: CGRect) {
        isToggled = false
        super.init(frame: frame)
        isSelected = false
    }
    
    required init?(coder: NSCoder) {
        isToggled = false
        super.init(coder: coder)
    }
    
    func toggle() {
        isToggled.toggle()
        isSelected.toggle()
    }
    
}
