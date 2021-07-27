//
//  ViewController.swift
//  SpeechToQuran
//
//  Created by Luthfi Abdurrahim on 27/07/21.
//

import UIKit
import Speech
import AVKit

class ViewController: UIViewController {

    //------------------------------------------------------------------------------
    // MARK:-
    // MARK:- Outlets
    //------------------------------------------------------------------------------

    @IBOutlet weak var btnStart             : UIButton!
    @IBOutlet weak var lblText              : UILabel!


    //------------------------------------------------------------------------------
    // MARK:- Variables
    //------------------------------------------------------------------------------

    let speechRecognizer        = SFSpeechRecognizer(locale: Locale(identifier: "ar_SA"))

    var recognitionRequest      : SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask         : SFSpeechRecognitionTask?
    let audioEngine             = AVAudioEngine()


    //------------------------------------------------------------------------------
    // MARK: Action Methods
    //------------------------------------------------------------------------------

    @IBAction func btnStartSpeechToText(_ sender: UIButton) {

        if audioEngine.isRunning {
            // Call to end recording            
            self.audioEngine.stop()
            self.recognitionRequest?.endAudio()
            self.btnStart.isEnabled = false
            self.btnStart.setTitle("Start Recording", for: .normal)
            
            if let labelText = self.lblText.text {
                AppClient.getSearchResult(query: labelText) { connection, array, error in
                    if let array = array {
                        let sortedArray = array.sorted { (lhs, rhs) in return lhs.index < rhs.index }
                        self.presentResultView(resultArray: sortedArray)
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
        //resultTableVC.modalPresentationStyle = .fullScreen
        present(resultTableVC, animated: true, completion: nil)
    }


    //------------------------------------------------------------------------------
    // MARK: Custom Methods
    //------------------------------------------------------------------------------

    func setupSpeech() {

        self.btnStart.isEnabled = false
        self.speechRecognizer?.delegate = self

        SFSpeechRecognizer.requestAuthorization { (authStatus) in

            var isButtonEnabled = false

            switch authStatus {
            case .authorized:
                isButtonEnabled = true

            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")

            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")

            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            @unknown default:
                fatalError()
            }

            OperationQueue.main.addOperation() {
                self.btnStart.isEnabled = isButtonEnabled
            }
        }
    }

    //------------------------------------------------------------------------------

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
                print("resultni")
                print(stringResult)
                isFinal = (result?.isFinal)!
            }

            if error != nil || isFinal {

                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.btnStart.isEnabled = true
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

        self.lblText.text = "Say something, I'm listening!"
    }


    //------------------------------------------------------------------------------
    // MARK: View Life Cycle Methods
    //------------------------------------------------------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSpeech()
    }
}


//------------------------------------------------------------------------------
// MARK: SFSpeechRecognizerDelegate Methods
//------------------------------------------------------------------------------

extension ViewController: SFSpeechRecognizerDelegate {

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.btnStart.isEnabled = true
        } else {
            self.btnStart.isEnabled = false
        }
    }
}
