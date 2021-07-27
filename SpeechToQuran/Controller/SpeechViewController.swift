//
//  SpeechViewController.swift
//  SpeechToQuran
//
//  Created by Luthfi Abdurrahim on 27/07/21.
//

import UIKit
import Speech
import AVKit
import CoreData

class SpeechViewController: UIViewController, NSFetchedResultsControllerDelegate {

          
    // MARK: Injected Properties
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Attempt>!
    
    // MARK:- Outlets
    @IBOutlet weak var btnStart             : UIButton!
    @IBOutlet weak var lblText              : UILabel!
    @IBOutlet weak var historyButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
        
    // MARK: Variables
    let defaultLabelText: String = "Press 'Start Recording', Then, Say something of one ayat in Al-Qur'an, I'm listening!"
    var searchResultAttempts: [SearchResultAttempt] = []
    
    let speechRecognizer        = SFSpeechRecognizer(locale: Locale(identifier: "ar_SA"))

    var recognitionRequest      : SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask         : SFSpeechRecognitionTask?
    let audioEngine             = AVAudioEngine()
    var arrayAttempts: [Attempt]!
    
    // MARK: View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSpeech()
        setupFetchedResultsController()
        handleNoInternet()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
        
    // MARK: Action Methods
    @IBAction func historyButtonPressed(_ sender: UIButton) {
        presentHistoryView(searchResultAttempts: searchResultAttempts)
    }
    
    @IBAction func btnStartSpeechToText(_ sender: UIButton) {
        if !Connectivity.isConnectedToInternet { handleNoInternet(); return }
        
        if audioEngine.isRunning {
            // Call to end recording
            setEnableUI(enabled: false)
            audioEngine.stop()
            recognitionRequest?.endAudio()
            btnStart.setTitle("Start Recording", for: .normal)
            
            if let labelText = self.lblText.text {
                if labelText == defaultLabelText {
                    setEnableUI(enabled: true)
                    return
                }
                AppClient.getSearchResult(query: labelText) { connection, array, error in
                    self.setEnableUI(enabled: true)
                    switch connection {
                    case .connected:
                        guard let array = array else {
                            self.showAlert("Sorry, There is no Result", message: error?.localizedDescription ?? "")
                            return
                        }
                        
                        guard error == nil else {
                            self.showAlert("Sorry, There is an Error(s)", message: error?.localizedDescription ?? "")
                            return
                        }
                        
                        let newAttempt = SearchResultAttempt(speechText: labelText, results: array, timestamp: Date())
                        //self.searchResultAttempts.append(newAttempt)
                        //self.addAttempt(speechText: labelText, array: array)
                        self.addAttempt(searchResultAttempt: newAttempt)
                        self.presentResultView(resultArray: array)
                    case .notConnected:
                        self.showAlert("There is no connection to internet, please try again.", message: "")
                    case .other:
                        self.showAlert("Error, please try again.", message: error?.localizedDescription ?? "")
                    }
                }
            }
        } else {
            // Call to start and end recording.
            self.startRecording()
            self.btnStart.setTitle("Stop Recording", for: .normal)
        }
    }
    
    // MARK: Present
    func presentResultView(resultArray: [AyatSearchResult]) {
        let resultTableVC = self.storyboard!.instantiateViewController(withIdentifier: "ResultTableViewController") as! ResultTableViewController
        resultTableVC.resultArray = resultArray
        lblText.text = defaultLabelText
        present(resultTableVC, animated: true, completion: nil)
    }
    
    func presentHistoryView(searchResultAttempts: [SearchResultAttempt]) {
        loadAttempts { results in
            let historyTableVC = self.storyboard!.instantiateViewController(withIdentifier: "HistoryTableViewController") as! HistoryTableViewController
            let sortedArray = results.sorted { (lhs, rhs) in return lhs.timestamp > rhs.timestamp }
            historyTableVC.searchResultAttempts = sortedArray
            historyTableVC.fetchedResultsController = self.fetchedResultsController
            self.lblText.text = self.defaultLabelText
            self.present(historyTableVC, animated: true, completion: nil)
        }
    }


    
    // MARK: Custom Methods
    
    func handleNoInternet() {
        if !Connectivity.isConnectedToInternet {
            showAlert("No Internet Connection.", message: "Please Activate your Internet Connection.")
            setEnableUI(enabled: false)
        }
    }
    
    func setEnableUI(enabled: Bool) {
        enabled ? activityIndicator.stopAnimating() : activityIndicator.startAnimating()
        btnStart.isEnabled = enabled
        historyButton.isEnabled = enabled
    }
    
    func setupSpeech() {

        setEnableUI(enabled: false)
        self.speechRecognizer?.delegate = self

        SFSpeechRecognizer.requestAuthorization { (authStatus) in

            var isButtonEnabled = false

            switch authStatus {
            case .authorized:
                isButtonEnabled = true

            case .denied:
                isButtonEnabled = false
                self.showAlert("Cannot go further..", message: "User denied access to speech recognition")
                print("User denied access to speech recognition")

            case .restricted:
                isButtonEnabled = false
                self.showAlert("Cannot go further..", message: "Speech recognition restricted on this device")
                print("Speech recognition restricted on this device")

            case .notDetermined:
                isButtonEnabled = false
                self.showAlert("Cannot go further..", message: "Speech recognition not yet authorized")
                print("Speech recognition not yet authorized")
            @unknown default:
                self.showAlert("Cannot go further..", message: "Please uninstall this app. Fatal Error.")
            }

            OperationQueue.main.addOperation() {
                self.setEnableUI(enabled: isButtonEnabled)
            }
        }
    }

    

    func startRecording() {

        // Clear all previous session data and cancel task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // Create instance of audio session to record voice
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record, mode: AVAudioSession.Mode.measurement, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }

        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true

        self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in

            var isFinal = false

            if result != nil {

                let stringResult : String = result?.bestTranscription.formattedString ?? ""
                self.lblText.text = stringResult                
                isFinal = (result?.isFinal)!
            }

            if error != nil || isFinal {

                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.setEnableUI(enabled: true)
            }
        })

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }

        self.audioEngine.prepare()

        do {
            try self.audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }

        self.lblText.text = defaultLabelText
    }
        
    private func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Attempt> = Attempt.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "attempt")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: Model Functions
    
    private func loadAttempts(completionHandler: @escaping ([SearchResultAttempt]) -> Void) {
        setupFetchedResultsController()
        searchResultAttempts = []
        if let attempts = fetchedResultsController.fetchedObjects {
            for item in attempts {
                let new = SearchResultAttempt(speechText: item.speechText!, results: nil, timestamp: item.creationDate!)
                searchResultAttempts.append(new)
            }
        }
        completionHandler(searchResultAttempts)
    }
    
    /// Adds a new attempt to the end of the array
    func addAttempt(searchResultAttempt: SearchResultAttempt) {
        let attempt = Attempt(context: dataController.viewContext)
        attempt.speechText = searchResultAttempt.speechText
        attempt.creationDate = Date()
        if let results = searchResultAttempt.results {
            for item in results {
                addResult(ayatSearchResult: item, attempt: attempt)
            }
        }
        if searchResultAttempts.count < 1 {
            searchResultAttempts.append(searchResultAttempt)
        }
        try? dataController.viewContext.save()
    }
    
    /// Adds a new result to the end of the array
    func addResult(ayatSearchResult: AyatSearchResult, attempt: Attempt) {
        let result = Result(context: dataController.viewContext)
        result.index = Int64(ayatSearchResult.index)
        result.text = ayatSearchResult.text
        result.suratName = ayatSearchResult.suratName
        result.suratId = Int64(ayatSearchResult.suratId)
        result.ayatId = Int64(ayatSearchResult.ayatId)
        result.ayatIdGlobal = Int64(ayatSearchResult.ayatIdGlobal)
        result.creationDate = Date()
        result.attempt = attempt
        try? dataController.viewContext.save()
    }
}



// MARK: SFSpeechRecognizerDelegate Methods

extension SpeechViewController: SFSpeechRecognizerDelegate {

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        setEnableUI(enabled: available)
    }
}


extension SpeechViewController {
    func showAlert(_ title: String,
                   message: String,
                   canCancel: Bool = false,
                   okTitle: String = "OK",
                   cancelTitle: String = "Cancel",
                   completionOk: @escaping () -> () = {  }) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
        alert.addAction(UIAlertAction(title: okTitle, style: .default, handler: { UIAlertAction in
            completionOk()
        }))
        
        if canCancel {
            alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: nil))
        }
        
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension UIImageView {
  func setImageColor(color: UIColor) {
    let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
    self.image = templateImage
    self.tintColor = color
  }
}
