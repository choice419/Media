//
//  ViewController.swift
//  Audio
//
//  Created by choice on 2017/1/20.
//  Copyright © 2017年 choice. All rights reserved.
//

import UIKit
import AudioToolbox

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func playAction(_ sender: Any) {
        playSoundEffect(name: "videoRing.caf")
    }
    
    /// 播放音效文件
    ///
    /// - Parameter name: 音频文件名称
    func playSoundEffect(name: String) {
        if let audioFile = Bundle.main.path(forResource: name, ofType: nil) {
            let fileUrl = NSURL(fileURLWithPath: audioFile)
            //1.获得系统声音ID
            var soundID: SystemSoundID = 0
            /**
             * inFileUrl:音频文件url
             * outSystemSoundID:声音id（此函数会将音效文件加入到系统音频服务中并返回一个长整形ID）
             */
            AudioServicesCreateSystemSoundID(fileUrl as CFURL, &soundID)
            //如果需要在播放完之后执行某些操作，可以调用如下方法
            AudioServicesPlaySystemSoundWithCompletion(soundID, {
                print("播放开始")
            })
            //如果需要在播放完之后执行某些操作，可以调用如下方法注册一个播放完成回调函数
            AudioServicesAddSystemSoundCompletion(soundID, nil, nil
            , { (soundid, nil) in
                print("播放完了")
            }, nil)
            
//            //2.播放音频
//            AudioServicesPlaySystemSound(soundID)
             //播放音效并震动
//            AudioServicesPlayAlertSound(soundID)
//            AudioServicesPlayAlertSoundWithCompletion(soundID, { 
//                print("播放完了")
//            })
//            AudioServicesAddSystemSoundCompletion(soundID, nil, nil
//                , { (soundid, nil) in
//                    print("播放开始")
//            }, nil)
        }
    }
}
