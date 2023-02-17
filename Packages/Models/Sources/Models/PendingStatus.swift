//
//  PendingStatus.swift
//  
//
//  Created by Jérôme Danthinne on 17/02/2023.
//

import Foundation

public struct PendingStatus {
  public let statusId: String
  public let accountId: String

  public init(status: Status) {
    statusId = status.id
    accountId = status.account.id
  }
}
