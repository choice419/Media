//
//  ViewController.swift
//  AVAudioiPlayer
//
//  Created by choice on 2017/1/26.
//  Copyright © 2017年 choice. All rights reserved.
//

import UIKit
import AVFoundation

private let kMusicFile = "刘若英 - 原来你也在这里.mp3"
private let kMusicSinger = "刘若英"

class ViewController: UIViewController {

    @IBOutlet weak var musicSingerLabel: UILabel!
    @IBOutlet weak var playProgress: UIProgressView!
    @IBOutlet weak var playOrPauseButton: UIButton!
    
    private var audioPlayer: AVAudioPlayer!
    private var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupUI() {
        musicSingerLabel.text = kMusicSinger
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
        
        //初始化播放器，注意这里的Url参数只能时文件路径，不支持HTTP Url
        guard let urlStr = Bundle.main.path(forResource: kMusicFile, ofType: nil) else {
            return
        }
        let url = NSURL.fileURL(withPath: urlStr)
        
        do {
            try audioPlayer = AVAudioPlayer(contentsOf: url)
        } catch {
            print("error")
        }
        //设置为0不循环
        audioPlayer.numberOfLoops = 0
        audioPlayer.delegate = self
        //加载音频文件到缓存
        audioPlayer.prepareToPlay()
        
        //设置后台播放模式
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
//            try audioSession.setCategory(AVAudioSessionCategoryPlayback, with: .allowBluetooth)
        } catch {
            print("error")
        }
        
        do {
            try audioSession.setActive(true)
        } catch {
            print("error")
        }
        
        //添加通知，拔出耳机后暂停播放
        NotificationCenter.default.addObserver(self, selector: Selector(("routeChange:")), name: NSNotification.Name(rawValue: AVAudioSessionRouteChangeReasonKey), object: nil)
    }
    
    func updateProgress() {
        let progress = audioPlayer.currentTime / audioPlayer.duration
        playProgress .setProgress(Float(progress), animated: true)
    }
    
    /**
     *  一旦输出改变则执行此方法
     *
     *  @param notification 输出改变通知对象
     */
    func routeChange(noti: Notification) {
        let dic = noti.userInfo
        if let changeReason = dic?[AVAudioSessionRouteChangeReasonKey] as? UInt {
            
            if changeReason == AVAudioSessionRouteChangeReason.oldDeviceUnavailable.rawValue {
                if let routeDescription = dic?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                    let portDescription = routeDescription.outputs.first
                    //原设备为耳机则暂停
                    if portDescription?.portType == "Headphones" {
                        audioPause()
                    }
                }
            }
        }
    }
    
    // MARK: 开始播放
    func audioPlay() {
        if !audioPlayer.isPlaying {
            audioPlayer.play()
            //恢复定时器
            timer.fireDate = NSDate.distantPast
        }
    }
    
    // MARK: 暂停播放
    func audioPause() {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
            //暂停定时器，注意不能调用invalidate方法，此方法会取消，之后无法恢复
            timer.fireDate = NSDate.distantFuture
        }
    }

    @IBAction func playAction(_ sender: Any) {
        if let button = sender as? UIButton {
            if button.tag == 0 {
                button.tag = 1
                button.setImage(#imageLiteral(resourceName: "playing_btn_pause_n"), for: .normal)
                button.setImage(#imageLiteral(resourceName: "playing_btn_pause_h"), for: .highlighted)
                audioPlay()
            } else {
                button.tag = 0
                button.setImage(#imageLiteral(resourceName: "playing_btn_play_n"), for: .normal)
                button.setImage(#imageLiteral(resourceName: "playing_btn_play_h"), for: .highlighted)
                audioPause()
            }
        }
    }
}

extension ViewController: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        //根据实际情况播放完成可以将会话关闭，其他音频应用继续播放
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            
        }
    }
    
}
