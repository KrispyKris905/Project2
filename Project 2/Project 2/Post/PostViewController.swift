
//
//  PostViewController.swift
//  BeRealDupe
//
//  Created by Cristobal Elizarrarz on 2/25/25.
//

import UIKit
import PhotosUI
import ParseSwift
import CoreLocation
import Foundation
import Photos

class PostViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var previewImageView: UIImageView!
    var post : Post?
    private var locationCity: String?
    private var locationCountry: String?

    private var pickedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func onPickedImageTapped(_ sender: UIBarButtonItem) {
        if PHPhotoLibrary.authorizationStatus(for: .readWrite) != .authorized {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                switch status {
                case .authorized:
                    DispatchQueue.main.async {
                        self?.presentImagePicker()
                    }
                default:
                    DispatchQueue.main.async {
                        self?.presentGoToSettingsAlert()
                    }
                }
            }
        } else {
            presentImagePicker()
        }
    }
    func presentGoToSettingsAlert() {
        let alertController = UIAlertController (
            title: "Photo Access Required",
            message: "In order to post a photo to complete a task, we need access to your photo library. You can allow access in Settings",
            preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }

        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
    
    private func presentImagePicker() {
        // TODO: Create, configure and present image picker.
        // Create a configuration object
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())

        // Set the filter to only show images as options (i.e. no videos, etc.).
        config.filter = .images

        // Request the original file format. Fastest method as it avoids transcoding.
        config.preferredAssetRepresentationMode = .current

        // Only allow 1 image to be selected at a time.
        config.selectionLimit = 1

        // Instantiate a picker, passing in the configuration.
        let picker = PHPickerViewController(configuration: config)

        // Set the picker delegate so we can receive whatever image the user picks.
        picker.delegate = self

        // Present the picker.
        present(picker, animated: true)
    }
    

    @IBAction func onShareTapped(_ sender: Any) {
        // Dismiss Keyboard
        view.endEditing(true)

        // TODO: Pt 1 - Create and save Post

        // Unwrap optional pickedImage
        guard let image = pickedImage,
              // Create and compress image data (jpeg) from UIImage
              let imageData = image.jpegData(compressionQuality: 0.1) else {
            return
        }

        // Create a Parse File by providing a name and passing in the image data
        let imageFile = ParseFile(name: "image.jpg", data: imageData)

        // Create Post object
        var post = Post()

        // Set properties
        post.imageFile = imageFile
        post.caption = captionTextField.text

        // Set the user as the current user
        post.user = User.current
        post.postUser = User.current?.username
        post.locationCity=locationCity
        post.locationCountry=locationCountry

        // Save post (async)
        post.save { [weak self] result in

            // Switch to the main thread for any UI updates
            DispatchQueue.main.async {
                switch result {
                case .success(let post):
                    print("✅ Post Saved! \(post)")
                    
                    // TODO: Pt 2 - Update user's last posted date
                    // Get the current user
                    if var currentUser = User.current {

                        // Update the `lastPostedDate` property on the user with the current date.
                        currentUser.lastPostedDate = Date()

                        // Save updates to the user (async)
                        currentUser.save { [weak self] result in
                            switch result {
                            case .success(let user):
                                print("✅ User Saved! \(user)")

                                // Switch to the main thread for any UI updates
                                DispatchQueue.main.async {
                                    // Return to previous view controller
                                    self?.navigationController?.popViewController(animated: true)
                                }

                            case .failure(let error):
                                self?.showAlert(description: error.localizedDescription)
                            }
                        }
                    }
                    self?.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }

    @IBAction func onTakePhotoTapped(_ sender: Any) {
        // TODO: Pt 2 - Present camera


    }

    @IBAction func onViewTapped(_ sender: Any) {
        // Dismiss keyboard
        view.endEditing(true)
    }
    func reverseGeocodeLocation(_ location: CLLocation, completion: @escaping (String, String) -> Void) {
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("❌ Reverse Geocoding failed: \(error.localizedDescription)")
                completion("Unknown", "Unknown")
                return
            }
            
            if let placemark = placemarks?.first {
                let city = placemark.locality ?? "Unknown City"
                let country = placemark.country ?? "Unknown Country"
                print("location: \(city), \(country)")
                completion(city, country)
            } else {
                completion("Unknown", "Unknown")
            }
        }
    }
}


// TODO: Pt 1 - Add PHPickerViewController delegate and handle picked image.
extension PostViewController: PHPickerViewControllerDelegate {

    // PHPickerViewController required delegate method.
    // Returns PHPicker result containing picked image data.
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

        // Dismiss the picker
        picker.dismiss(animated: true)

        // Make sure we have a non-nil item provider
        guard let provider = results.first?.itemProvider,
              // Make sure the provider can load a UIImage
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        // Load a UIImage from the provider
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in

            // Make sure we can cast the returned object to a UIImage
            guard let image = object as? UIImage else {
                self?.showAlert()
                return
            }

            // Check for and handle any errors
            if let error = error {
                self?.showAlert(description: error.localizedDescription)
                return
            } else {

                // UI updates (like setting image on image view) should be done on main thread
                DispatchQueue.main.async {

                    // Set image on preview image view
                    self?.previewImageView.image = image

                    // Set image to use when saving post
                    self?.pickedImage = image
                }
            }
            
        }
        if let assetId = results.first?.assetIdentifier {
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
                
                if let asset = assets.firstObject, let location = asset.location {
                    reverseGeocodeLocation(location) { city, country in
                        self.locationCity=city
                        self.locationCountry=country
                        // You can store this data or display it in the UI
                    }
                } else {
                    print("⚠️ No location metadata found for this image.")
                }
            }
    }
}


// TODO: Pt 2 - Add UIImagePickerControllerDelegate + UINavigationControllerDelegate
