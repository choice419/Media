//
//  ViewController.swift
//  AVAudioRecorder
//
//  Created by choice on 2017/2/13.
//  Copyright © 2017年 choice. All rights reserved.
//

import UIKit
import AVFoundation

private let kRecordAudioFile = "/myRecord.caf"

class ViewController: UIViewController {

    @IBOutlet weak var audioPower: UIProgressView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var resumeButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    //音频录音机
    private var audioRecorder: AVAudioRecorder!
    //音频播放器，用于播放录音文件
    var audioPlayer: AVAudioPlayer!
    //录音声波监控（注意这里暂时不对播放进行监控）
    private var timer: Timer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setAudioSession()
        setAudioRecorder()
        setAudioPlayer()
        setTimer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     *  设置音频会话
     */
    func setAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            //设置为播放和录音状态，以便可以在录制完之后播放录音
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioSession.setActive(true)
        } catch {
            
        }
    }
    
    /**
     *  取得录音文件保存路径
     *
     *  @return 录音文件路径
     */
    func getSavePath() -> URL {
        var urlStr = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last
        
        urlStr = urlStr?.appending(kRecordAudioFile)
        print("file path = \(urlStr)")
        let url = URL(fileURLWithPath: urlStr!)
        return url
    }
    
    /**
     *  取得录音文件设置
     *
     *  @return 录音设置
     */
    func getAudioSetting() -> [String: Any] {
        var dicM: [String: Any] = [:]
        //设置录音格式
        dicM[AVFormatIDKey] = kAudioFormatLinearPCM
        //设置录音采样率，8000是电话采样率，对于一般录音已经够了
        dicM[AVSampleRateKey] = 8000
        //设置通道,这里采用单声道
        dicM[AVNumberOfChannelsKey] = 1
        //每个采样点位数,分为8、16、24、32
        dicM[AVLinearPCMBitDepthKey] = 8
        //是否使用浮点数采样
        dicM[AVLinearPCMIsFloatKey] = true
        return dicM
    }
    
    // 设置录音机对象
    func setAudioRecorder() {
        let url = getSavePath()
        let setting = getAudioSetting()
        do {
            try audioRecorder = AVAudioRecorder(url: url, settings: setting)
        } catch {
            print("error")
        }
        audioRecorder.delegate = self
        //如果要监控声波则必须设置为YES
        audioRecorder.isMeteringEnabled = true
    }
    
    // 设置播放对象
    func setAudioPlayer() {
        let url = getSavePath()
        do {
            try audioPlayer = AVAudioPlayer(contentsOf: url)
        } catch {
            print("error")
        }
        audioPlayer.numberOfLoops = 0
        audioPlayer.prepareToPlay()
    }
    
    //设置定时器
    func setTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(audioPowerChange), userInfo: nil, repeats: true)
        timer.fireDate = NSDate.distantFuture
    }
    
    /**
     *  录音声波状态设置
     */
    func audioPowerChange() {
        //更新测量值
        audioRecorder.updateMeters()
        //取得第一个通道的音频，注意音频强度范围时-160到0
        let power = audioRecorder.averagePower(forChannel: 0)
        let progress = (1.0 / 160.0) * (power + 160.0)
        audioPower.setProgress(progress, animated: true)
    }
    
    //点击录音
    @IBAction func recordAction(_ sender: Any) {
        if !audioRecorder.isRecording {
            //首次使用应用时如果调用record方法会询问用户是否允许使用麦克风
            audioRecorder.record()
            timer.fireDate = NSDate.distantPast
        }
    }
    
    //点击暂定
    @IBAction func pauseAction(_ sender: Any) {
        if audioRecorder.isRecording {
            audioRecorder.pause()
            timer.fireDate = NSDate.distantFuture
        }
    }
    
    //点击恢复按钮
    //恢复录音只需要再次调用record，AVAudioSession会帮助你记录上次录音位置并追加录音
    @IBAction func resumeAction(_ sender: Any) {
        recordAction(sender)
    }
    
    //点击停止按钮
    @IBAction func stopAction(_ sender: Any) {
        audioRecorder.stop()
        timer.fireDate = NSDate.distantFuture
        audioPower.progress = 0.0
    }
    
}

extension ViewController: AVAudioRecorderDelegate {
    /**
     *  录音完成，录音完成后播放录音
     *
     *  @param recorder 录音机对象
     *  @param flag     是否成功
     */
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !audioPlayer.isPlaying {
            audioPlayer.play()
        }
        print("录音完成！")
    }
}
