#!/bin/bash

cd Sources/Acheron

echo -e "\nAcheron ========================"
cloc .

echo -e "\nLoom ORM ======================="
cloc Loom/Anchor.swift\
     Loom/Basket.swift\
     Loom/Domain.swift\
     Loom/Persist.swift\
     Loom/Loom.swift\
     Loom/SQLite/SQLitePersist.swift

echo -e "\nAepLayout ======================"
cloc Interface/AEViewController.swift\
     Interface/Screen.swift\
     Extensions/CALayer+Acheron.swift\
     Extensions/UIView+Acheron.swift\
     Extensions/UIViewController+Acheron.swift

echo -e "\nPen ============================"
cloc Utility/Pen.swift\
     Extensions/NSMutableAttributedString+Acheron.swift\
     Extensions/NSString+Acheron.swift\
     Extensions/UIButton+Acheron.swift\
     Extensions/UILabel+Acheron.swift

echo -e "\nRGB ============================"
cloc Utility/RGB.swift\
     Extensions/UIColor+Acheron.swift

echo -e "\nExpandable Table View =========="
cloc Interface/ExpandableCell.swift\
     Interface/ExpandableTableView.swift

echo -e "\nNode View ======================"
cloc Interface/AETableView.swift\
     Interface/NodeView/Node.swift\
     Interface/NodeView/NodeCell.swift\
     Interface/NodeView/NodeColumn.swift\
     Interface/NodeView/NodeData.swift\
     Interface/NodeView/NodeHeader.swift\
     Interface/NodeView/NodeView.swift

echo -e "\nAepImage ======================="
cloc Extensions/UIImage+Acheron.swift\
     Extensions/UIImageView+Acheron.swift

echo -e "\nPond and Pebbles ==============="
cloc Pebbles/Pebble.swift\
     Pebbles/Pond.swift\
     Pebbles/BackgroundPond.swift

echo -e "\nOdds and Ends =================="
cloc Utility/AESync.swift\
     Utility/AETimer.swift\
     Utility/SafeMap.swift\
     Utility/SafeSet.swift\
     Utility/WeakSet.swift\
     Utility/XMLtoAttributes.swift\
     Interface/SplitterView.swift\
     Interface/TripWire.swift\
     Extensions/Array+Acheron.swift\
     Extensions/CaseIterable+Acheron.swift\
     Extensions/CGPoint+Acheron.swift\
     Extensions/Codable+Acheron.swift\
     Extensions/Comparable+Acheron.swift\
     Extensions/Date+Acheron.swift\
     Extensions/Dictionary+Acheron.swift\
     Extensions/String+Acheron.swift\
     Extensions/UIControl+Acheron.swift
