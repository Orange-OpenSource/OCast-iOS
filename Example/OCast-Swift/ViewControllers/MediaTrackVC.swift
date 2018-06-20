//
// MediaTrackVC.swift
//
// Copyright 2017 Orange
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import OCast

extension MainVC {
    
    func getTrack (from tracks: [TrackDescription], atIndex index: Int) -> (current : String, next: String) {
        
        let enabledTrack = tracks.filter {item -> Bool in
            return item.enabled == true
        }
        
        let currentTrack = enabledTrack.first?.language ?? "--"
        
        let tracksIDs = tracks.map {item -> String in
            return item.id
        }
        
        let nextID = (index + 1) % tracks.count
        
        let nextTrackLanguage = tracks.filter {item->Bool in
            return item.id == tracksIDs[nextID]
        }
        
        let nextTrack = nextTrackLanguage.first?.language ?? "--"

        return (currentTrack, nextTrack)
    }
    
    func updateTracks (from data: Metadata) {
        
        if let newTracks = data.audioTracks {
            
            if newTracks.count > 0 {
                
                audioTrackButton.isHidden = false
                audioTracks = newTracks
                
                let tracks = getTrack(from: audioTracks, atIndex: currentAudioIdx)
                
                audioTrackButton.setTitle("Set Audio track to \(tracks.next == "" ? "--": tracks.next)", for: .normal)
                audioTrackLabel.text = tracks.current == "" ? "--" :tracks.current
                
            }
        }
        
        if let newTracks = data.videoTracks {
            
            if newTracks.count > 0 {
                
                videoTrackButton.isHidden = false
                videoTracks = newTracks
                
                let tracks = getTrack(from: videoTracks, atIndex: currentVideoIdx)
                
                videoTrackButton.setTitle("Set Video track to \(tracks.next == "" ? "--": tracks.next)", for: .normal)
                videoTrackLabel.text = tracks.current == "" ? "--" :tracks.current
            }
        }
        
        if let newTracks = data.textTracks {
            
            if newTracks.count > 0 {
                
                textTrackButton.isHidden = false
                textTracks = newTracks
                
                let tracks = getTrack(from: textTracks, atIndex: currentTextIdx)
                
                textTrackButton.setTitle("Set Text track to \(tracks.next == "" ? "--": tracks.next)", for: .normal)
                textTrackLabel.text = tracks.current == "" ? "--" :tracks.current
            }
        }
        
        
    }
    
    //MARK: - Tracks control
    
    @IBAction func onAudioButton(_ sender: Any) {
        
        let tracksIDs = audioTracks.map {item -> String in
            return item.id
        }
        
        
        let nextIdx = (currentAudioIdx + 1) % audioTracks.count
        
        appliMgr?.mediaController.track(type: .audio, id: tracksIDs[nextIdx], enabled: true,
                               onSuccess: {
                                DispatchQueue.main.async {
                                    OCastLog.debug("-> Audio track is set.")
                                    self.currentAudioIdx = nextIdx
                                   // self.onGetMetaData(self)
                                }
        },
                               onError: {_ in
                                DispatchQueue.main.async {
                                    self.audioTrackButton.setTitleColor(UIColor.red, for: .normal)
                                    OCastLog.debug("-> Audio track could not be set.")}
        })
        
    }
    
    
    @IBAction func onVideoButton(_ sender: Any) {
        
        let tracksIDs = videoTracks.map {item -> String in
            return item.id
        }
        
        let nextIdx = (currentVideoIdx + 1) % videoTracks.count
        
        appliMgr?.mediaController.track(type: .video, id: tracksIDs[nextIdx], enabled: true,
                               onSuccess: {
                                DispatchQueue.main.async {
                                    OCastLog.debug("-> Video track is set.")
                                     self.currentVideoIdx = nextIdx
                                    //self.onGetMetaData(self)
                                }
        },
                               onError: {_ in
                                DispatchQueue.main.async {
                                    self.videoTrackButton.setTitleColor(UIColor.red, for: .normal)
                                    OCastLog.debug("-> Video track could not be set.")}
        })
        
    }
    
    @IBAction func onTextButton(_ sender: Any) {
        let tracksIDs = textTracks.map {item -> String in
            return item.id
        }
        
        let nextIdx = (currentTextIdx + 1) % textTracks.count
        
        appliMgr?.mediaController.track(type: .text, id: tracksIDs[nextIdx], enabled: true,
                               onSuccess: {
                                    DispatchQueue.main.async {
                                        OCastLog.debug("-> Text track is set.")
                                        self.currentTextIdx = nextIdx
                                    }
                               },
                               onError: {_ in
                                DispatchQueue.main.async {
                                    self.textTrackButton.setTitleColor(UIColor.red, for: .normal)
                                    OCastLog.debug("-> Text track could not be set.")}
                                })
        
    }

}
