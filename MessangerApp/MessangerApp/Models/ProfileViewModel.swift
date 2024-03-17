//
//  ProfileViewModel.swift
//  MessangerApp
//
//  Created by beyza nur on 17.03.2024.
//

import Foundation

enum ProfileViewModelType {
    case info , logout
}
struct ProfileViewModel{
    let viewModelType : ProfileViewModelType
    let title : String
    let handler : (() -> Void )?
}
