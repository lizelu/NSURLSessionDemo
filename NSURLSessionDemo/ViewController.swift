//
//  ViewController.swift
//  AlamofireDemo
//
//  Created by Mr.LuDashi on 16/5/16.
//  Copyright © 2016年 ZeluLi. All rights reserved.
//

import UIKit
import SystemConfiguration

let kFileResumeData = "ResumeData"                  // 存储resumeData的Key
let keyBackgroundDownload = "backgroundDownload"    //BackgroundSession的标示

class ViewController: UIViewController, URLSessionDelegate, URLSessionTaskDelegate,URLSessionDownloadDelegate, URLSessionDataDelegate, URLSessionStreamDelegate{
    
    @IBOutlet var logTextView: UITextView!
    @IBOutlet var uploadImageView: UIImageView!
    @IBOutlet var downloadProgressView: UIProgressView!
    
    
    var downloadTask: URLSessionDownloadTask? = nil
    var downloadSession: Foundation.URLSession? = nil
    
    var etag: String? = nil
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //创建BackgroundDownloadSession
        let config = URLSessionConfiguration.background(withIdentifier: keyBackgroundDownload)
        self.downloadSession = Foundation.URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
//        let defaultSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
//        let ephemeralSessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
//        let backgroundSessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfiguration("标示")
//        let testSession = NSURLSession(configuration: defaultSessionConfiguration)
    }
    
    
    
    
    
    /**
     通过NSURLSessionDataTask进行get请求
     
     - parameter sender:
     */
    @IBAction func tapSessionGetButton(_ sender: AnyObject) {
        let parameters = ["userId": "1"]
        showLog("正在GET请求数据" as AnyObject)
        sessionDataTaskRequest("GET", parameters: parameters as [String : AnyObject])
    }
    
    
    
    /**
     通过NSURLSessionDataTask进行Post请求
     
     - parameter sender:
     */
    @IBAction func tapSessionPostButton(_ sender: AnyObject) {
        showLog("正在POST请求数据" as AnyObject)
        let parameters = ["userId": "1"]
        
        sessionDataTaskRequest("POST", parameters: parameters as [String : AnyObject])
    }
    
    /**
     NSURLSessionDataTask
     - parameter method:     请求方式：POST或者GET
     - parameter parameters: 字典形式的参数
     */
    
    func sessionDataTaskRequest(_ method: String, parameters:[String:AnyObject]){
        //1.创建会话用的URL
        var hostString = "http://jsonplaceholder.typicode.com/posts"
        let escapeQueryString = query(parameters)   //对参数进行URL编码
        if method == "GET" {
            hostString += "?" + escapeQueryString
        }
        let url: URL = URL.init(string: hostString)!
        
        //2.创建Request
        var request = URLRequest(url: url)
        request.httpMethod = method //指定请求方式
        if method == "POST" {
            request.httpBody = escapeQueryString.data(using: String.Encoding.utf8)
        }
        
        //3.获取Session单例，创建SessionDataTask
        let session: Foundation.URLSession = Foundation.URLSession.shared
        let sessionTask = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if error != nil {
                self.showLog(error! as AnyObject)
                return
            }

            if data != nil {    //对Data进行Json解析
                let json = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
                self.showLog(json! as AnyObject)
            }
        }
        sessionTask.resume()
    }
    
    
    
    /**
     测试URL编码
     
     - parameter sender: 
     */
    @IBAction func tapURLEncodeButton(_ sender: AnyObject) {
        showLog("URL编码测试" as AnyObject)
        let parameters = ["post": "value01",
                          "arr": ["元素1", "元素2"],
                          "dic":["key1":"value1", "key2":"value2"]] as [String : Any]
        showLog(query(parameters as [String : AnyObject]) as AnyObject)
    }
    
    
    
    
    
    
    /**
     通过NSURLSessionUploadTask进行数据上传
     
     - parameter sender:
     */
    @IBAction func tapSessionUploadFileButton(_ sender: AnyObject) {
        self.downloadProgressView.progress = 0
         showLog("正在上传数据" as AnyObject)
        
        let path = Bundle.main.path(forResource: "test", ofType: "png")
        //let path: String? = "http://d.3987.com/yej_141216/009.jpg"
        var imageData : Data?
        
        
        let dispatchGroup = DispatchGroup()
        DispatchQueue.global().async(group: dispatchGroup, qos: .default, flags: .assignCurrentContext) { 
             imageData = try? Data.init(contentsOf: URL(fileURLWithPath: path!))
        }
        
        dispatchGroup.notify(queue: DispatchQueue.global()) { //将上述的图片上传到服务器
           
            DispatchQueue.main.async(execute: {                         //更新主线程
                self.uploadImageView.image = UIImage.init(data: imageData!)
            })
            
            self.uploadTask(imageData!)                                         //将fileData上传到服务器
        }
    }
    
    /**
     上传图片到服务器，NSURLSessionUploadTask的使用
     
     - parameter parameters: 上传到服务器的二进制文件
     */
    func uploadTask(_ parameters: Data) {
        //let uploadUrlString = "https://httpbin.org/post"
        let uploadUrlString = "http://127.0.0.1/upload.php"
        
        let url: URL = URL.init(string: uploadUrlString)!
        
        var request = URLRequest.init(url: url)
        request.httpMethod = "POST"
        
        let session: Foundation.URLSession = Foundation.URLSession.init(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        
        let uploadTask = session.uploadTask(with: request, from: parameters) { (data, response, error) in
            if error != nil{
                self.showLog((error?._code)! as AnyObject)
                self.showLog(error.debugDescription as AnyObject)
            }else{
                self.showLog("上传成功" as AnyObject)
            }

        }
        
        //使用resume方法启动任务
        uploadTask.resume()
        
        //会执行NSURLSessionTaskDelegate中的didSendBodyData回调方法监听上传进度
    }

    

    
    /**
     图片开始的下载
     
     - parameter sender:
     */
    
    @IBAction func tapDownloadTaskButton(_ sender: AnyObject) {
        showLog("正在下载图片" as AnyObject)
        //获取ResumeData
        let resumeData: Data? =  UserDefaults.standard.object(forKey: kFileResumeData) as? Data
        
        if (resumeData != nil) {
            self.downloadTask = self.downloadSession?.downloadTask(withResumeData: resumeData!)
        }else{
            //let fileUrl: NSURL? = NSURL(string: "http://data.vod.itc.cn/?rb=1&prot=1&key=jbZhEJhlqlUN-Wj_HEI8BjaVqKNFvDrn&prod=flash&pt=1&new=/107/94/cs1SqPgtR2u0jueLoUh3CA.mp4")
            let fileUrl: URL? = URL(string: "https://pic.cnblogs.com/avatar/545446/20140828105334.png")
            let request: URLRequest = URLRequest(url: fileUrl!)
            self.downloadTask = self.downloadSession?.downloadTask(with: request)
        }
        
        downloadTask?.resume()  // 开始任务
    }
    
    
    /**
     暂停下载
     
     - parameter sender:
     */
    @IBAction func tapPauseButton(_ sender: AnyObject) {
        print(NSTemporaryDirectory())   //打印临时文件路径
        showLog("暂停下载任务" as AnyObject)
        
        downloadTask?.cancel(byProducingResumeData: { (resumeData) in
            /**
             *  此处的resumeData并不是已经下载的文件的Data而是存储下载信息的Data
             *  将该Data进行解析，是一个xml格式的数据，其中存储着下载链接以及上次下载数据
             */
            if resumeData != nil {
                
                if let str = String.init(data: resumeData!, encoding: String.Encoding.utf8) {
                    print(str)
                }
                UserDefaults.standard.set(resumeData, forKey: kFileResumeData)
                
                //resumeData每次输出的大小没有多少区别
                self.showLog("resumeData的长度\((resumeData?.count)!)" as AnyObject)
            }
        })
    }
    
    
    
    
    
    
    
    /**
     缓存策略：
        UseProtocolCachePolicy -- 缓存存在就读缓存，若不存在就请求服务器
        ReloadIgnoringLocalCacheData -- 忽略缓存，直接请求服务器数据
        ReturnCacheDataElseLoad -- 本地如有缓存就使用，忽略其有效性，无则请求服务器
        ReturnCacheDataDontLoad -- 直接加载本地缓存，没有也不请求网络
        ReloadIgnoringLocalAndRemoteCacheData -- 未实现
        ReloadRevalidatingCacheData -- 未实现
     
     - parameter sender:
     */
    
    
     //1.使用URLRequest指定缓存策略
    @IBAction func tapRequestCacheButton(_ sender: AnyObject) {
        showLog("使用URLRequest指定缓存策略" as AnyObject)
        
        let fileUrl: URL? = URL(string: "http://www.baidu.com")
        var request = URLRequest(url: fileUrl!)
        
        request.cachePolicy = .returnCacheDataElseLoad
        
        let session: Foundation.URLSession = Foundation.URLSession.shared
        let dataTask: URLSessionDataTask = session.dataTask(with: request) {
            (data, response, error) in
            if data != nil {
                self.showLog("缓存数据长度 = \((data?.count)!)" as AnyObject)
            }
        }
        dataTask.resume()//05DC72D9-764F-4D0A-B137-AA0C32C9D682
    }
    
    
    //2.使用NSURLSessionConfiguration指定缓存策略
    @IBAction func tapConfigurationCacheButton(_ sender: AnyObject) {
        showLog("使用NSURLSessionConfiguration指定缓存策略" as AnyObject)
        
        let fileUrl: URL? = URL(string: "http://www.baidu.com")
        let request = URLRequest(url: fileUrl!)
        
        let sessionConfig: URLSessionConfiguration = URLSessionConfiguration.default
        
        sessionConfig.requestCachePolicy = .returnCacheDataElseLoad
        
        let session: Foundation.URLSession = Foundation.URLSession(configuration: sessionConfig)

        
        let dataTask: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            if data != nil {
                self.showLog("缓存数据长度 = \((data?.count)!)" as AnyObject)
            }
        }
        dataTask.resume()

    }

    //3.使用URLCache + request进行缓存
    @IBAction func tapRequestURLCacheButton(_ sender: AnyObject) {
        showLog("使用URLCache + request进行缓存" as AnyObject)
        
        let fileUrl: URL? = URL(string: "http://www.cnblogs.com")
        var request = URLRequest(url: fileUrl!)
        
        let memoryCapacity = 4 * 1024 * 1024    //内存容量
        let diskCapacity = 10 * 1024 * 1024     //磁盘容量
        let cacheFilePath: String = "MyCache"   //缓存路径
        
        let urlCache: URLCache = URLCache(memoryCapacity: memoryCapacity,
                                              diskCapacity: diskCapacity,
                                              diskPath: cacheFilePath)
        URLCache.shared = urlCache
        
        request.cachePolicy = .returnCacheDataElseLoad
        let session: Foundation.URLSession = Foundation.URLSession.shared
        
        let dataTask: URLSessionDataTask = session.dataTask(with: request) {
            (data, response, error) in
            if data != nil {
                self.showLog("缓存数据长度 = \((data?.count)!)" as AnyObject)
            }
        }
        dataTask.resume()
    }
    
    //4.使用URLCache + NSURLSessionConfiguration进行缓存
    @IBAction func tapConfigNSURLCacheButton(_ sender: AnyObject) {
        
        showLog("使用URLCache + NSURLSessionConfiguration进行缓存" as AnyObject)
        
        let fileUrl: URL? = URL(string: "http://www.cnblogs.com")
        let request = URLRequest(url: fileUrl!)
        
        let memoryCapacity = 4 * 1024 * 1024    //内存容量
        let diskCapacity = 10 * 1024 * 1024     //磁盘容量
        let cacheFilePath: String = "MyCache"   //缓存路径-相对路径，位于~/Library/Caches

        let urlCache: URLCache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: cacheFilePath)
        
        let sessionConfig: URLSessionConfiguration = URLSessionConfiguration.default
        sessionConfig.requestCachePolicy = .returnCacheDataElseLoad
        sessionConfig.urlCache = urlCache
        
        let session: Foundation.URLSession = Foundation.URLSession(configuration: sessionConfig)
        
        
        let dataTask: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            if data != nil {
                self.showLog("缓存数据长度 = \((data?.count)!)" as AnyObject)
            }
        }
        
        dataTask.resume()
    }
    
    
    
    
    @IBAction func tapAuthenticationButton(_ sender: AnyObject) {
        let url = URL.init(string: "https://www.xinghuo365.com/index.shtml")
        let request = URLRequest(url: url!)
        
        let sessionConfig = URLSessionConfiguration.default
        let session = Foundation.URLSession.init(configuration: sessionConfig,
                                        delegate: self,
                                        delegateQueue: OperationQueue.main)
        
        let sessionDataTask = session.dataTask(with: request) {
            (data, response, error) in
            if data != nil {
                self.showLog("数据长度 = \((data?.count)!)" as AnyObject)
            }
        }
        
        sessionDataTask.resume()
    }
    
    
    
    
    /**
     使用Delegate来处理网络相关的请求
     
     - parameter sender: 
     */
    @IBAction func tapSessionDelegateButton(_ sender: AnyObject) {
        //代理+Cache
       // let fileUrl: NSURL? = NSURL(string: "https://www.xinghuo365.com/index.shtml")//不会重定向
        let fileUrl: URL? = URL(string: "https://www.xinghuo365.com")               //会重定向
        var requestFile = URLRequest(url: fileUrl!)
        
        requestFile.cachePolicy = .returnCacheDataElseLoad  //指定缓存策略
        
        //使用NSURLSessionDataDelegate处理相应数据
        let sessionConfig = URLSessionConfiguration.default
        let sessionWithDelegate = Foundation.URLSession.init(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let sessionDataTask = sessionWithDelegate.dataTask(with: requestFile)
        
        sessionDataTask.resume()
    }
    
    
    
    
    
    //Network Reachability
    
    let reachability = SCNetworkReachabilityCreateWithName(nil, "www.baidu.com")
    
    @IBAction func tapSCNetworkReachabilityButton(_ sender: AnyObject) {
        //1.创建reachability上下文
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        
        //2.设置回调
        let clouserCallBackEnable = SCNetworkReachabilitySetCallback(reachability!, { (reachability, flags, info) in
            print("reachability=\(reachability)\ninfo=\(String(describing: info))\nflags=\(flags)\n")
            
            guard flags.contains(SCNetworkReachabilityFlags.reachable) else {
                print("网络不可用")
                return
            }
            
            if !flags.contains(SCNetworkReachabilityFlags.connectionRequired) {
                print("以太网或者WiFi")
            }
            
            if flags.contains(SCNetworkReachabilityFlags.connectionOnDemand) ||
               flags.contains(SCNetworkReachabilityFlags.connectionOnTraffic) {
                if !flags.contains(SCNetworkReachabilityFlags.interventionRequired) {
                    print("以太网或者WiFi")
                }
            }
            
            #if os(iOS)
                if flags.contains(SCNetworkReachabilityFlags.isWWAN) {
                    print("蜂窝数据")
                }
            #endif
        },
        &context)
       
        //3.将reachability添加到执行队列
        let queueEnable = SCNetworkReachabilitySetDispatchQueue(reachability!,  DispatchQueue.main)
        
        if clouserCallBackEnable && queueEnable {
            print("已监听网络状态")
        }
    }
    
    
    
    @IBAction func tapCacheTestButton(_ sender: AnyObject) {
        let fileUrl: URL? = URL(string: "http://127.0.0.1/test.html")
        
        var requestFile: URLRequest = URLRequest(url: fileUrl!)
        
        requestFile.cachePolicy = .useProtocolCachePolicy  //指定缓存策略
        
        //使用NSURLSessionDataDelegate处理相应数据
        let sessionConfig = URLSessionConfiguration.default
        let sessionWithDelegate = Foundation.URLSession.init(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let sessionDataTask = sessionWithDelegate.dataTask(with: requestFile)
        
        sessionDataTask.resume()

    }
    
    

    //MARK - NSURLSessionDelegate-----------------
    
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("Session已无效")
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("后台事件已处理完毕")
        DispatchQueue.main.async { 
            self.downloadProgressView.progress = 1
        }
    }
    
    /**
     认证方式
        NSURLAuthenticationMethodHTTPBasic: HTTP基本认证，需要提供用户名和密码
        NSURLAuthenticationMethodHTTPDigest: HTTP数字认证，与基本认证相似需要用户名和密码
        NSURLAuthenticationMethodHTMLForm: HTML表单认证，需要提供用户名和密码
        NSURLAuthenticationMethodNTLM: NTLM认证，NTLM（NT LAN Manager）是一系列旨向用户提供认证，完整性和机密性的微软安全协议
        NSURLAuthenticationMethodNegotiate: 协商认证
        NSURLAuthenticationMethodClientCertificate: 客户端认证，需要客户端提供认证所需的证书
        NSURLAuthenticationMethodServerTrust: 服务端认证，由认证请求的保护空间提供信任
     */
    
    /**
     处理证书的策略: NSURLSessionAuthChallengeDisposition
        UseCredential： 使用证书
        PerformDefaultHandling： 执行默认处理, 类似于该代理没有被实现一样，credential参数会被忽略
        CancelAuthenticationChallenge： 取消请求，credential参数同样会被忽略
        RejectProtectionSpace： 拒绝保护空间，重试下一次认证，credential参数同样会被忽略
     
     
    */
    
    

    /**
     请求数据时，如果服务器需要验证，那么就会调用下方的代理方法
     
     - parameter session:           session
     - parameter challenge:         授权质疑
     - parameter completionHandler:
     */
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        let authenticationMethod = challenge.protectionSpace.authenticationMethod   //从保护空间中取出认证方式
        
        if authenticationMethod == NSURLAuthenticationMethodServerTrust {           //从保护空间中取出认证方式
            showLog("服务器信任证书" as AnyObject)
            let disposition = Foundation.URLSession.AuthChallengeDisposition.useCredential    //处理策略
            let credential = URLCredential.init(trust: challenge.protectionSpace.serverTrust!) //创建证书
            completionHandler(disposition, credential) //证书处理
            return
        }
        /**
         *  HTTP基本认证和数字认证
         *  NSURLCredentialPersistence
         *      None ：要求 URL 载入系统 “在用完相应的认证信息后立刻丢弃”。
         *      ForSession ：要求 URL 载入系统 “在应用终止时，丢弃相应的 credential ”。
         *      Permanent ：要求 URL 载入系统 "将相应的认证信息存入钥匙串（keychain），以便其他应用也能使用。
         */
        if authenticationMethod == NSURLAuthenticationMethodHTTPBasic {
            let credential = URLCredential.init(user: "username", password: "password", persistence: URLCredential.Persistence.forSession)
            
            let disposition = Foundation.URLSession.AuthChallengeDisposition.useCredential    //处理策略
            completionHandler(disposition, credential)
            return
        }
        //取消请求
        let disposition = Foundation.URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge
        completionHandler(disposition, nil)
    }
    
    
    

    
    
    
    //MARK ------------- NSURLSessionTaskDelegate------------------------------
    /**
     请求被重定向后会执行下方的方法
     
     - parameter session:
     - parameter task:
     - parameter response:  请求的响应头
     - parameter request:   被重定向后的request
     - parameter completionHandler: 处理句柄
     */
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        
        print(response)
        print(request.url ?? "")              //Optional(https://www.xinghuo365.com/index.shtml)
        print(request.cachePolicy)      //NSURLRequestCachePolicy
        
        //可以对重定向后request中的URL进行修改
        if var mutableURLRequest = (request as NSURLRequest).mutableCopy() as? URLRequest {
            mutableURLRequest.url = URL(string: "http://www.baidu.com") //会再次重定向到本地
            completionHandler(mutableURLRequest as URLRequest)
            return
        }
        
        completionHandler(request)
    }
    
    /**
     向服务器发送数据所调用的方法，可以监听文件上传进度
     
     - parameter session:
     - parameter task:
     - parameter bytesSent:                 本次上传
     - parameter totalBytesSent:            已上传
     - parameter totalBytesExpectedToSend:  文件总大小
     */
    //taskDidSendBodyDataBytesSentTotalBytesSendTotalBytesExpectedToSend
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        showLog("\n本次上传：\(bytesSent)B" as AnyObject)
        showLog("已上传：\(totalBytesSent)B" as AnyObject)
        showLog("文件总量：\(totalBytesExpectedToSend)B" as AnyObject)
        
        //获取进度
        let written:Float = (Float)(totalBytesSent)
        let total:Float = (Float)(totalBytesExpectedToSend)
        DispatchQueue.main.async {
            self.downloadProgressView.progress = written/total
        }

    }
    
    //处理认证想代码，参见上述NSURLSessionDelegate中的对应的方法
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    needNewBodyStream
        completionHandler: @escaping (InputStream?) -> Void) {
    }
    
    //任务执行完毕后会执行下方的请求
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            print(error?._userInfo ?? "")
        }
        print("task\(task.taskIdentifier)执行完毕")
    }
    
    
    
    
    

    // MARK -- NSURLSessionDataDelegate===========================
    
    /**
     * NSURLSessionResponseDisposition
     *  .Cancel 取消加载，默认为 .Cancel
     *  .Allow 允许继续操作, 会执行 dataTaskDidReceiveData回调方法
     *  .BecomeDownload 将请求转变为DownloadTask，会执行NSURLSessionDownloadDelegate
     *  .BecomeStream 将请求变成StreamTask，会执行NSURLSessionStreamDelegate
     */

    
    /**
     收到响应时会执行下方的方法
     
     - parameter session:
     - parameter dataTask:
     - parameter response:          服务器响应
     - parameter completionHandler: 指定处理响应的策略
     */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        showLog("响应头：\(response)" as AnyObject)

        guard let httpResponse = response as? HTTPURLResponse else {
           return
        }
        
        guard let etag = httpResponse.allHeaderFields["Etag"] as? String else {
            return
        }
        
        
        if self.etag == nil {
            self.etag = etag
        } else {
            
            if self.etag == etag {
                completionHandler(.cancel)
                
                
                
            } else {
                completionHandler(.allow)
            }
            
        }

        
        
        
//        completionHandler(.Cancel)
//        completionHandler(.BecomeDownload)

//        if #available(iOS 9.0, *) {
//            completionHandler(.BecomeStream)
//        }
        
        completionHandler(.allow)
    }
    
    
    
    
    /**
     在执行dataTask时，接收数据后会调用下方的方法
     
     - parameter session:
     - parameter dataTask:
     - parameter data:     接收的数据
     */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                    didReceive data: Data) {
        print(data)
        if let str = String.init(data: data, encoding: String.Encoding.utf8) {
            showLog(str as AnyObject)
        }
    }

    
    /**
     变成DownLoadTask会调用的方法
     
     - parameter session:
     - parameter dataTask:
     - parameter downloadTask:
     */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                    didBecome downloadTask: URLSessionDownloadTask) {
        showLog("任务已经变成DownLoadTask" as AnyObject)
    }
    
    /**
     *  变成StreamTask会调用下方的方法
     */
    @available(iOS 9.0, *)
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                    didBecome streamTask: URLSessionStreamTask) {
        showLog("任务已经变成StreamTask" as AnyObject)
    }
    
    
    /**
     将要缓存响应时会触发下述方法
     */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                    willCacheResponse proposedResponse: CachedURLResponse,
                    completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        let data = proposedResponse.data
        if let str = String.init(data: data, encoding: String.Encoding.utf8) {
            print(str)
        }
        
        print(proposedResponse.storagePolicy)   //NSURLCacheStoragePolicy
        print(proposedResponse.userInfo ?? "")
        print(proposedResponse.response)
        
        //对缓存响应进行处理
 //       completionHandler(proposedResponse)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK ------------NSURLSessionDownloadDelegate------------------
    /**
     下载完成后执行的代理
     
     - parameter session:      session对象
     - parameter downloadTask: downloadTask对象
     - parameter location:     本地URL
     */
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        UserDefaults.standard.removeObject(forKey: kFileResumeData)
        
        showLog("下载的临时文件路径:\(location)" as AnyObject)                //输出下载文件临时目录
         let tempFilePath: String = location.path
        
        //创建文件存储路径
        let newFileName = String(UInt(Date().timeIntervalSince1970))
        var newFileExtensionName = "txt"
        if session.configuration.identifier == keyBackgroundDownload {
            newFileExtensionName = "png"
        }
        let newFilePath: String = NSHomeDirectory() + "/Documents/\(newFileName).\(newFileExtensionName)"
        showLog("将临时文件进行存储，路径为:\(newFilePath)" as AnyObject)

        let fileManager:FileManager = FileManager.default           //创建文件管理器
        try! fileManager.moveItem(atPath: tempFilePath, toPath: newFilePath)       //将临时文件移动到新目录中
        
        if downloadTask == self.downloadTask {                                  //将下载后的图片进行显示
            let imageData = try? Data(contentsOf: URL(fileURLWithPath: newFilePath))
            DispatchQueue.main.async {
                self.uploadImageView.image = UIImage.init(data: imageData!)
            }
        }
    }
    
    /**
     实时监听下载任务回调
     
     - parameter session:                   session对象
     - parameter downloadTask:              下载任务
     - parameter bytesWritten:              本次接收
     - parameter totalBytesWritten:         总共接收
     - parameter totalBytesExpectedToWrite: 总量
     */
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                                 totalBytesWritten: Int64,
                                 totalBytesExpectedToWrite: Int64) {
        showLog("\n本次接收：\(bytesWritten)B" as AnyObject)
        showLog("已下载：\(totalBytesWritten)B" as AnyObject)
        showLog("文件总量：\(totalBytesExpectedToWrite)B" as AnyObject)
        
        //获取进度
        let written:Float = (Float)(totalBytesWritten)
        let total:Float = (Float)(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.downloadProgressView.progress = written/total
        }
    }
    
    /**
     下载偏移，主要用于暂停续传
     
     - parameter session:
     - parameter downloadTask:
     - parameter fileOffset:            已下载多少
     - parameter expectedTotalBytes:    文件大小
     */
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("已经下载：\(fileOffset)")
        print("文件总量：\(expectedTotalBytes)")
        
        DispatchQueue.main.async {
            self.downloadProgressView.progress = Float(fileOffset/expectedTotalBytes)
        }
    }

    
    
    
    
    
    
    //MARK -- NSURLSessionStreamDelegate----------------------------------------
    
    
    /**
     当StreamTask进行closeRead时会执行该代理方法
     
     - parameter session:
     - parameter streamTask:
     */
    @available(iOS 9.0, *)
    func urlSession(_ session: URLSession, readClosedFor streamTask: URLSessionStreamTask) {
        
        //因为read已经被关闭了，所以下方的闭包是不会执行的
        streamTask.readData(ofMinLength: 0, maxLength: 1024*1024, timeout: 0) { (data, bool, error) in
            print(streamTask.countOfBytesReceived)
        }

    }
    
    @available(iOS 9.0, *)
    func urlSession(_ session: URLSession, writeClosedFor streamTask: URLSessionStreamTask) {
        
        //读取流，数据，并进行二进制解析
        streamTask.readData(ofMinLength: 0, maxLength: 1024*1024, timeout: 0) { (data, bool, error) in
            print(streamTask.countOfBytesReceived)
            print(data ?? "")
            let json = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
            self.showLog(json! as AnyObject)
        }
        streamTask.closeRead();
        
        
    }
    
    @available(iOS 9.0, *)
    func urlSession(_ session: URLSession, betterRouteDiscoveredFor streamTask: URLSessionStreamTask) {
    }
    
    @available(iOS 9.0, *)
    func urlSession(_ session: URLSession, streamTask: URLSessionStreamTask, didBecome inputStream: InputStream, outputStream: OutputStream) {
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    // - MARK - Alamofire中的三个方法该方法将字典转换成URL编码的字符
    func query(_ parameters: [String: AnyObject]) -> String {
        
        var components: [(String, String)] = []     //存有元组的数组，元组由ULR中的(key, value)组成
        
        for key in parameters.keys.sorted(by: <) {        //遍历参数字典
            let value = parameters[key]!
            components += queryComponents(key, value)
        }
        
        return (components.map { "\($0)=\($1)" } as [String]).joined(separator: "&")
    }
    
    
    func queryComponents(_ key: String, _ value: AnyObject) -> [(String, String)] {
        var components: [(String, String)] = []
        
        
        if let dictionary = value as? [String: AnyObject] {         //value为字典的情况, 递归调用
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        }
            
        else if let array = value as? [AnyObject] {               //value为数组的情况, 递归调用
            for value in array {
                components += queryComponents("\(key)[]", value)
            }
        }
        
        else {  //vlalue为字符串的情况，进行转义，上面两种情况最终会递归到此情况而结束
            components.append((escape(key), escape("\(value)")))
        }
        
        return components
    }
    
    /**
     
     - parameter string: 要转义的字符串
     
     - returns: 转义后的字符串
     */
    func escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        
        var escaped = ""
        
        //==========================================================================================================
        //
        //  Batching is required for escaping due to an internal bug in iOS 8.1 and 8.2. Encoding more than a few
        //  hundred Chinese characters causes various malloc error crashes. To avoid this issue until iOS 8 is no
        //  longer supported, batching MUST be used for encoding. This introduces roughly a 20% overhead. For more
        //  info, please refer to:
        //
        //      - https://github.com/Alamofire/Alamofire/issues/206
        //
        //==========================================================================================================
        if #available(iOS 8.3, *) {
            escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
        } else {
            let batchSize = 50
            var index = string.startIndex
            
            while index != string.endIndex {
                let startIndex = index
                let endIndex = string.index(index, offsetBy: batchSize, limitedBy: string.endIndex) ?? string.endIndex
                let range = startIndex..<endIndex
                
                let substring = string.substring(with: range)
                
                escaped += substring.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? substring
                
                index = endIndex
            }
        }
        
        return escaped
    }
    
    
    
    
    


    
    //清除日志以及缓存
    @IBAction func tapClearLogButton(_ sender: AnyObject) {
        UserDefaults.standard.removeObject(forKey: kFileResumeData)
        self.logTextView.text = ""
        clearCacheFile()
    }
    
    /**
     清理缓存文件
     */
    func clearCacheFile() {
        //获取缓存文件路径
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        
        //获取BoundleID
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return
        }
        
        //拼接当前工程所创建的缓存文件路径
        let projectCashPath = "\(cachePath)/\(bundleIdentifier)/"
        
        //创建FileManager
        let fileManager: FileManager = FileManager.default
        
        //获取缓存文件列表
        guard let cacheFileList = try?fileManager.contentsOfDirectory(atPath: projectCashPath) else {
            return
        }
        
        //遍历文件列表，移除所有缓存文件
        for fileName in cacheFileList {
            let willRemoveFilePath = projectCashPath + fileName
            
            if fileManager.fileExists(atPath: willRemoveFilePath) {
                try!fileManager.removeItem(atPath: willRemoveFilePath)
            }
        }
    }
    
    
    func showLog(_ info: AnyObject) {
        let log = "\(info)"
        print(log)
        
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
        DispatchQueue.main.async {
            
            semaphore.wait()
            let logs = self.logTextView.text
            let newlogs = String((logs! + "\n"+log)).replacingOccurrences(of: "\\n", with: "\n")
            

            self.logTextView.text = newlogs
            
            self.logTextView.layoutManager.allowsNonContiguousLayout = false
            self.logTextView.scrollRectToVisible(CGRect(x: 0, y: self.logTextView.contentSize.height - 15, width: self.logTextView.contentSize.width, height: 10), animated: true)
            
            semaphore.signal()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

