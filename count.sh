#!/bin/bash

cd ./Acheron

echo -e "\nAcheron ========================"
cloc ./*.swift

echo -e "\nLoom ORM ======================="
cloc ./Anchor.swift\
     ./Basket.swift\
     ./Domain.swift\
     ./Persist.swift\
     ./Loom.swift\
     ./SQLitePersist.swift

echo -e "\nAepLayout ======================"
cloc ./AEViewController.swift\
     ./Screen.swift\
     ./CALayer+Acheron.swift\
     ./UIView+Acheron.swift\
     ./UIViewController+Acheron.swift

echo -e "\nPen ============================"
cloc ./Pen.swift\
     ./NSMutableAttributedString+Acheron.swift\
     ./NSString+Acheron.swift\
     ./UIBUtton+Acheron.swift\
     ./UILabel+Acheron.swift

echo -e "\nRGB ============================"
cloc ./RGB.swift\
     ./UIColor+Acheron.swift

echo -e "\nExpandable Table View =========="
cloc ./ExpandableCell.swift\
     ./ExpandableTableView.swift

echo -e "\nNode View ======================"
cloc ./AETableView.swift\
     ./Node.swift\
     ./NodeCell.swift\
     ./NodeColumn.swift\
     ./NodeData.swift\
     ./NodeHeader.swift\
     ./NodeView.swift

echo -e "\nAepImage ======================="
cloc ./UIImage+Acheron.swift\
     ./UIImageView+Acheron.swift

echo -e "\nPond and Pebbles ==============="
cloc ./Pebble.swift\
     ./Pond.swift

echo -e "\nOdds and Ends =================="
cloc ./AESync.swift\
     ./AETimer.swift\
     ./SafeMap.swift\
     ./SafeSet.swift\
     ./WeakSet.swift\
     ./XMLtoAttributes.swift\
     ./TripWire.swift\
     ./Array+Acheron.swift\
     ./CaseIterable+Acheron.swift\
     ./CGPoint+Acheron.swift\
     ./Comparable+Acheron.swift\
     ./Date+Acheron.swift\
     ./Dictionary+Acheron.swift\
     ./String+Acheron.swift\
     ./UIControl+Acheron.swift
