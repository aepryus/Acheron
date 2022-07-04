//
//  CellsView.swift
//  
//
//  Created by Joe Charlier on 6/26/22.
//  Copyright © 2022 Aepryus Software. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public protocol CellsViewDelegate: AnyObject {
    func cellsView(_ cellsView: CellsView, numberOfRowsInSection section: Int) -> Int
    func cellsView(_ cellsView: CellsView, cellForRowAt indexPath: IndexPath) -> CellsViewCell
    
    func numberOfSections(in cellsViewcellsView: CellsView) -> Int
//    func cellsView(_ cellsView: CellsView, titleForHeaderInSection section: Int) -> String?
//    func cellsView(_ cellsView: CellsView, titleForFooterInSection section: Int) -> String?
//    func cellsView(_ cellsView: CellsView, canEditRowAt indexPath: IndexPath) -> Bool
//    func cellsView(_ cellsView: CellsView, canMoveRowAt indexPath: IndexPath) -> Bool
//    func sectionIndexTitles(for cellsView: CellsView) -> [String]?
//    func cellsView(_ cellsView: CellsView, sectionForSectionIndexTitle title: String, at index: Int) -> Int
//    func cellsView(_ cellsView: CellsView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
//    func cellsView(_ cellsView: CellsView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)

//    func numberOfSections(_ cellsView: CellsView, heightForIndexPath: IndexPath) -> Int
//    func numberOfRows(_ section) -> Int
//    func cellsView(_ cellsView: CellsView, heightForIndexPath: IndexPath) -> CGFloat
//    func cellsView(_ cellsView: CellsView, cellForIndexPath: IndexPath) -> UIView

    //    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    //    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    //    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
    //    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath)
    //    func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int)
    //    func tableView(_ tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int)
    func cellsView(_ cellsView: CellsView, heightForRowAt indexPath: IndexPath) -> CGFloat
    //    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    //    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    //    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat
    //    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat
    //    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat
    //    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    //    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    //    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath)
    //    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool
    //    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath)
    //    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath)
    //    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath?
    //    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath?
    //    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    //    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
    //    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle
    //    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String?
    //    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    //    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    //    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    //    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool
    //    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath)
    //    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?)
    //    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath
    //    func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int
    //    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool
    //    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool
    //    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?)
    //    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool
    //    func tableView(_ tableView: UITableView, shouldUpdateFocusIn context: UITableViewFocusUpdateContext) -> Bool
    //    func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator)
    //    func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath?
    //    func tableView(_ tableView: UITableView, selectionFollowsFocusForRowAt indexPath: IndexPath) -> Bool
    //    func tableView(_ tableView: UITableView, shouldSpringLoadRowAt indexPath: IndexPath, with context: UISpringLoadedInteractionContext) -> Bool
    //    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool
    //    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath)
    //    func tableViewDidEndMultipleSelectionInteraction(_ tableView: UITableView)
    //    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration?
    //    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview?
    //    func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview?
    //    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating)
    //    func tableView(_ tableView: UITableView, willDisplayContextMenu configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?)
    //    func tableView(_ tableView: UITableView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?)

}

public class CellsView: UIScrollView, UITableViewDelegate {
    private var cells: [String:UIView] = [:]
    weak var cellsViewDelegate: CellsViewDelegate?
    
    private let bufferHeight: CGFloat = 200*Screen.s
    
    public init() {
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func render() {
        guard let delegate: CellsViewDelegate  = cellsViewDelegate else { return }
        var y: CGFloat = 0
        var section: Int = 0
        var row: Int = 0
        let maxSections: Int = delegate.numberOfSections(in: self)
        var maxRows: Int = delegate.cellsView(self, numberOfRowsInSection: section)
        var started: Bool = false
        var current: IndexPath = IndexPath(row: 0, section: 0)
        var height: CGFloat = 0
        
        while y < contentOffset.y + contentSize.height + bufferHeight {
            current = IndexPath(row: row, section: section)
            height = delegate.cellsView(self, heightForRowAt: current)
            
            if !started && y + height > contentOffset.y - bufferHeight { started = true }

            if started {
                let cell: CellsViewCell = delegate.cellsView(self, cellForRowAt: current)
                cell.frame = CGRect(x: 0, y: y, width: width, height: height)
            }
            
            y += height
            
            row += 1
            if row == maxRows {
                section += 1
                row = 0
                maxRows = delegate.cellsView(self, numberOfRowsInSection: section)
                if section == maxSections { break }
            }
        }
    }
    
// UIScrollView ====================================================================================================
    public override var contentOffset: CGPoint {
        didSet {
        }
    }
}

#endif
