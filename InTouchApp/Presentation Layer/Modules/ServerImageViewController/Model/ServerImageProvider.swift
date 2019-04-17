//
//  ServerImageProvider.swift
//  InTouchApp
//
//  Created by Михаил Борисов on 16/04/2019.
//  Copyright © 2019 Mikhail Borisov. All rights reserved.
//

import UIKit

class ServerImageProvider: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var view: UIView? // передаем view экрана
    weak var delegate: SaveDelegate?
    var data: [CellDisplayModel] = []
    let serverViewController = RootAmbessy()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    /// Загружаем ячейку
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ServerCell", for: indexPath) as? ServerImageCollectionViewCell else { fatalError() }
        guard let imageUrl = URL(string: data[indexPath.row].imageUrl) else { fatalError("Failed to get URl.  ") }
        
        do {
            let imageData = try Data(contentsOf: imageUrl)
            cell.serverImage.image = UIImage(data: imageData)
        } catch {
            print(error.localizedDescription)
        }
        return cell
    }
    
    /// Задаем размер ячейки
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let view = view else { fatalError("No view found") }
        let withHeight = (view.layer.frame.width - 40) / 3
        return CGSize(width: withHeight, height: withHeight)
    }
    
    /// Возвращаемся обратно в профиль
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.save(sender: self)
    }
}
