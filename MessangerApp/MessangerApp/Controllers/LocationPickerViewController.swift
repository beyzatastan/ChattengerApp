//
//  LocationPickerViewController.swift
//  MessangerApp
//
//  Created by beyza nur on 15.03.2024.
//

import UIKit
import CoreLocation
import MapKit

 final class LocationPickerViewController: UIViewController {

    public var completion : ((CLLocationCoordinate2D) -> Void)?
    private var coordinates : CLLocationCoordinate2D?
    private var isPickable = true
    private let map : MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    init(coordinates : CLLocationCoordinate2D?){
        self.coordinates = coordinates
        self.isPickable = coordinates == nil
        super.init(nibName:nil,bundle:nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()  
        view.backgroundColor = .systemBackground
        if isPickable{
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send",
                                                                style: .done,
                                                                target: self,
                                                                action: #selector(sendButtonTapped))

            map.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
            
        }else{
            //just showing location
            guard let coordinates = self.coordinates else{
                return
            }
            //mapte zoom in yapabilmek içib
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
        }
        view.addSubview(map)
        
    }
    
    @objc func sendButtonTapped(){
        guard let coordinates = coordinates else{
            return
        }
        navigationController?.popToRootViewController(animated: true)
        completion?(coordinates)
        
    }
    
    @objc func didTapMap(_ gesture: UITapGestureRecognizer){
        let locationInView = gesture.location(in: map)
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)
        self.coordinates = coordinates
        
        //BAŞKA BİR PİN OLUŞTURDUĞUMUZDA DİĞER PİNİN YOK OLMASINI SAĞLIYOR
        for annotation in map.annotations{
            map.removeAnnotation(annotation)
        }
        
        //drop pin on that location
        //yani kullanıcı bastığında orayı pinle
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }


}
