//
// MediaVC.swift
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
    
    //MARK: - Media Controller protocol

    func didReceiveEvent(metadata: Metadata) {
        OCastLog.debug(("-> MetaData from MediaController: \(metadata)"))
        
        metadataTitleLabel.text = metadata.title
        updateTracks(from: metadata)
    }
    
    func didReceiveEvent(playbackStatus: PlaybackStatus) {
        mediaDuration = playbackStatus.duration
        
        OCastLog.debug("-> MediaStatus position: \(playbackStatus.position.format(f: ".2"))")
        OCastLog.debug("-> MediaStatus duration: \(playbackStatus.duration.format(f: ".2"))")
        OCastLog.debug("-> MediaStatus playerState: \(playbackStatus.state.rawValue)")
        OCastLog.debug("-> MediaStatus Volume: \(playbackStatus.volume)")
        
        durationLabel.text = String (playbackStatus.duration.format(f: ".1"))
        positionLabel.text = String (playbackStatus.position.format(f: ".1"))
        
        switch playbackStatus.state {
        case .buffering:    playerStateLabel.text = "buffering"
        case .idle: playerStateLabel.text = "idle"
        case .paused:   playerStateLabel.text = "paused"
        case .playing:  playerStateLabel.text = "playing"
        case .unknown:  playerStateLabel.text = "unknown"
        }
        
        volumeLabel.text = String (playbackStatus.volume.format(f: ".1"))
        volumeSlider.value = Float(playbackStatus.volume)
        
        seekSlider.value = Float (playbackStatus.position/mediaDuration)
    }
    
    //MARK: - Media general control
    
    @IBAction func onSeekSlider(_ sender: UISlider) {
        
        let position = sender.value * Float (mediaDuration)
        
        mediaController?.seek(to: UInt(position),
                              onSuccess: {
                                OCastLog.debug("->Seek is OK.")
                              },
                              onError: {error in
                                OCastLog.debug("->Seek is NOK. Code = \(String(describing: error?.code))")
                                
                              }
            
        )
    }
    
    @IBAction func onVolumeSlider(_ sender: UISlider) {
        
        mediaController?.volume(to: sender.value,
                                onSuccess: {
                                    OCastLog.debug("->Volume is OK.")
                                },
                                onError: {error in
                                    OCastLog.debug("->Volume is NOK. Code = \(String(describing: error?.code))")
                                    
                                }
            
        )
        
        
    }
    


    
    @IBAction func onMusicButton(_ sender: Any) {
        
        let prepareMedia = MediaPrepare (
            url: URL(string: "http://archive.org/download/MIXG031/02_Intoxicated_Piano_-_In_My_Dreams.mp3")!,
            frequency : 1,
            title: "In my dreams",
            subtitle: "Intoxicated_Piano",
            logo: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/")!,
            mediaType: .audio,
            transferMode: .streamed,
            autoplay: true)
        
        mediaController?.prepare(for: prepareMedia,
                                 onSuccess: {
                                    OCastLog.debug("->Prepare for music is OK.")
        },
                                 onError: {error in
                                    OCastLog.debug("->Prepare for music is NOK. Code = \(String(describing: error?.code))")
                                    
        }
        )

    }
    
    @IBAction func onPictureButton(_ sender: Any) {
        let prepareMedia = MediaPrepare (
            url: URL(string: "https://www.orange.com/var/orange_site/storage/images/orange.com/accueil/carrousel-de-la-home-page/derniers-resultats-consolides/965840-1-fre-FR/Derniers-resultats-consolides_main-slider.jpg")!,
            frequency : 1,
            title: "Brand refresh purple",
            subtitle: "Brought to you by Orange OCast",
            logo: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/")!,
            mediaType: .image,
            transferMode: .buffered,
            autoplay: true)
        
        mediaController?.prepare(for: prepareMedia,
                                 onSuccess: {
                                    DispatchQueue.main.async {
                                    OCastLog.debug("->Prepare for picture is OK.")
                                    self.pictureLabel.text = "Picture sent."}
                                },
                                 onError: {error in
                                    DispatchQueue.main.async {
                                    OCastLog.debug("->Prepare for picture is NOK. Code = \(String(describing: error?.code))")
                                    self.pictureLabel.text = "Picture could not be sent."}
                                    
                                }
        )

    }
    
    
    
    @IBAction func onMediaCtrlCast(_ sender: Any) {
       
        // http://sample.vodobox.com/planete_interdite/planete_interdite_alternate.m3u8
        // https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8
        
        let prepareMedia = MediaPrepare (
            url: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!,
            frequency : 1,
            title: "Movie sample",
            subtitle: "Brought to you by Orange OCast",
            logo: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/")!,
            mediaType: .video,
            transferMode: .streamed,
            autoplay: true)

        mediaController?.prepare(for: prepareMedia,
                                 onSuccess: {
                                    OCastLog.debug("->Prepare for film is OK.")
                                },
                                 onError: {error in
                                    OCastLog.debug("->Prepare for film is NOK. Code = \(String(describing: error?.code))")
                                    
                                }
        )
    }
    
    @IBAction func onMediaPause(_ sender: Any) {
        
        if shouldPause {
            
            
            mediaController?.pause(onSuccess: {
                                    OCastLog.debug("->Pause is OK.")
                                    },
                                   
                                    onError: {error in
                                        OCastLog.debug("->Pause is NOK. Code = \(String(describing: error?.code))")
                                    }
            )
            
        } else {
            
            mediaController?.resume(onSuccess: {
                                    OCastLog.debug("->Resume is OK.")
                                    },
                                    
                                    onError: {error in
                                        OCastLog.debug("->Resume is NOK. Code = \(String(describing: error?.code))")
                                    }
            )
        }
        
        shouldPause = !shouldPause
    }
    
    @IBAction func onMute(_ sender: Any) {
        mediaController?.mute(isMuted: shouldMute,
                              onSuccess: {
                                
                                if self.shouldMute {
                                    OCastLog.debug("->Mute is OK.")
                                    self.muteButton.setTitle("UnMute", for: .normal)
                                } else {
                                    OCastLog.debug("->UnMute is OK.")
                                    self.muteButton.setTitle("Mute", for: .normal)
                                }
                                self.shouldMute = !self.shouldMute
                                },
                              
                             onError: {error in
                                OCastLog.debug("->Mute is NOK. Code = \(String(describing: error?.code))")
                             }
        )
    }
    
    @IBAction func onMediaCtrlStop(_ sender: Any) {
        mediaController?.stop(onSuccess: {
                                OCastLog.debug("->Stop is OK.")
                            },
                            onError: {error in
                                OCastLog.debug("->Stop is NOK. Code = \(String(describing: error?.code))")
                                
                            })
    }
    

    
    @IBAction func onPlayerStatus(_ sender: Any) {
        mediaController?.playbackStatus(
            onSuccess: { playbackStatus in
                        OCastLog.debug("->PlayBack Status is OK.")
                        self.playbackPosition.text = String (playbackStatus.position.format(f: ".1"))
                
            },
            onError: {error in
                OCastLog.debug("->PlayBackp is NOK. Code = \(String(describing: error?.code))")
                self.playbackPosition.text = "Error= \(String(describing: error?.code))"
                
            }
        )
    }
    
    @IBAction func onGetMetaData(_ sender: Any) {
        mediaController?.metadata(
            onSuccess: { metadata in
                OCastLog.debug("->MetaData is OK.")
                 self.didReceiveEvent(metadata: metadata)
                
        },
            onError: {error in
                OCastLog.debug("->MetaData is NOK. Code = \(String(describing: error?.code))")
                self.metadataTitleLabel.text = "Error= \(String(describing: error?.code))"
                
        }
        )
        
    }
}
