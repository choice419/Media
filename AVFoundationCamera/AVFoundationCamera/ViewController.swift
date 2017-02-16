//
//  ViewController.swift
//  AVFoundationCamera
//
//  Created by choice on 2017/2/15.
//  Copyright © 2017年 choice. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var flashAutoButton: UIButton!
    @IBOutlet weak var flashOnButton: UIButton!
    @IBOutlet weak var flashOffButton: UIButton!
    
    //负责输入和输出设置之间的数据传递
    private var captureSession: AVCaptureSession!
    //负责从AVCaptureDevice获得输入数据
    private var captureDeviceInput: AVCaptureDeviceInput!
    //照片输出流
    private var captureStillImageOutput: AVCaptureStillImageOutput!
    //相机拍摄预览图层
    private var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initCapture()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // 初始化信息
    func initCapture() {
        //创建AVCaptureSession对象
        captureSession = AVCaptureSession()
        //设置分辨率
        if captureSession!.canSetSessionPreset(AVCaptureSessionPreset1280x720){
            captureSession!.sessionPreset = AVCaptureSessionPreset1280x720
        }
        
        //获得输入设备
        let captureDevice = getCameraDeviceWithPostion(position: .back)
        if captureDevice?.position != .back {
            print("获取后置摄像头失败")
            return
        }
        
        //根据使用设备初始化输出设备对象audioCaptureDevice
        do {
            captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch {
            print("获取输出设备失败")
            return
        }
        
        
        //初始化输出对象，用于获得输出数据
        captureStillImageOutput = AVCaptureStillImageOutput()
        let outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        captureStillImageOutput.outputSettings = outputSettings
        
        
        //将设备输入添加到会话中
        if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
        }
        
        //将设备输出添加到会话中
        if captureSession.canAddOutput(captureStillImageOutput) {
            captureSession.addOutput(captureStillImageOutput)
        }
        
        //创建视频预览层，用于实时展示摄像头状态
        captureVideoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession)
        let layer = view.layer
        layer.masksToBounds = true
        captureVideoPreviewLayer.frame = layer.bounds
        //填充模式
        captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.insertSublayer(captureVideoPreviewLayer, at: 0)
        captureSession.startRunning()
        
    }
    
    /**
     *  取得指定位置的摄像头
     *
     *  @param position 摄像头位置
     *
     *  @return 摄像头设备
     */
    func getCameraDeviceWithPostion(position: AVCaptureDevicePosition) -> AVCaptureDevice! {
        let cameras = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        for camera in cameras! {
            if let camera = camera as? AVCaptureDevice {
                if camera.position == position {
                    return camera
                }
            }
        }
        return nil
    }
    
    // 设置闪光灯按钮状态
    func setFlashModeStatus() {
        if let captureDevice = captureDeviceInput.device {
            let flashMode = captureDevice.flashMode
            if captureDevice.isFlashAvailable {
                flashAutoButton.isHidden = false
                flashOnButton.isHidden = false
                flashOffButton.isHidden = false
                flashAutoButton.isEnabled = true
                flashOnButton.isEnabled = true
                flashOffButton.isEnabled = true
                switch flashMode {
                case .auto:
                    flashAutoButton.isEnabled = false
                    break
                case .on:
                    flashOnButton.isEnabled = false
                    break
                case .off:
                    flashOffButton.isEnabled = false
                    break
                }
            } else {
                flashAutoButton.isHidden = true
                flashOnButton.isHidden = true
                flashOffButton.isHidden = true
            }
        }
    }
    
    /**
     *  设置聚焦光标位置
     *
     *  @param point 光标位置
     */
    func setFocusCursorWithPoint(point: CGPoint) {
        let captureConnection = captureStillImageOutput.connection(withMediaType: AVMediaTypeVideo)
        captureStillImageOutput.captureStillImageAsynchronously(from: captureConnection) { (imageDataSamplebuffer, error) in
            if error == nil {
                if let tempData = imageDataSamplebuffer {
                    if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(tempData)
                    {
                        if let image = UIImage(data: imageData) {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        }
                    }
                }
            }
        }
    }
    
    /**
     *  设置聚焦点
     *
     *  @param point 聚焦点
     */
    func focusWithMode(focusMode: AVCaptureFocusMode, exposureMode: AVCaptureExposureMode, point: CGPoint) {
        changeDevideProperty { (captureDevice) in
            //是否支持对焦模式
            if captureDevice.isFocusModeSupported(focusMode) {
                captureDevice.focusMode = .autoFocus
            }
            
            //是否支持手动对焦模式
            if captureDevice.isFocusPointOfInterestSupported {
                captureDevice.focusPointOfInterest = point
            }
            
            //是否支持曝光模式
            if captureDevice.isExposureModeSupported(exposureMode) {
                captureDevice.exposureMode = .autoExpose
            }
            
            //是否支持手动曝光模式
            if captureDevice.isExposurePointOfInterestSupported {
                captureDevice.exposurePointOfInterest = point
            }
        }
    }
    
    /**
     *  改变设备属性的统一操作方法
     *
     *  @param propertyChange 属性改变操作
     */
    func changeDevideProperty(propertychange: (AVCaptureDevice) ->()) {
        if let captureDevice = captureDeviceInput.device {
            do {
                //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
                try captureDevice.lockForConfiguration()
                propertychange(captureDevice)
                captureDevice.unlockForConfiguration()
            } catch {
                print("设置设备属性过程发生错误，错误信息")
            }
        }
    }

    @IBAction func takeCamareAction(_ sender: Any) {
    }
    
    @IBAction func changeCameraPositionAction(_ sender: Any) {
    }
    
    @IBAction func flashAutoAction(_ sender: Any) {
    }
    
    @IBAction func flashOnAction(_ sender: Any) {
    }
    
    @IBAction func flashOffAction(_ sender: Any) {
    }
    
}

