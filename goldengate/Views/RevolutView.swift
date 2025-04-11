import SwiftUI
import WebKit

class RevolutViewController: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView!
    private let url: String = "https://app.revolut.com/start"
    private let transactionUrl: String = "https://app.revolut.com/api/retail/transaction/67e17485-5f3f-af4a-8f2c-a7a92bfcaa5b"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadInitialURL()
    }

    // MARK: - Setup WebView
    private func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        view.addSubview(webView)
        setupWebViewConstraints()
    }

    private func setupWebViewConstraints() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }

    // MARK: - Load URL
    private func loadInitialURL() {
        guard let url = URL(string: url) else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let currentURL = webView.url else { return }
        print("Finished loading URL: \(currentURL)")

        // Extract and send cookies after the page has finished loading
        extractCookies { [weak self] cookies in
            self?.sendRequestWithCookies(cookies)
        }
    }

    // MARK: - Handle Cookies and Request
    private func extractCookies(completion: @escaping ([String: [HTTPCookie]]) -> Void) {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies { cookies in
            // Group cookies by their name to handle duplicates
            let cookieMap = Dictionary(grouping: cookies, by: { $0.name })
            completion(cookieMap)
        }
    }

    private func sendRequestWithCookies(_ cookieMap: [String: [HTTPCookie]]) {
        guard let url = URL(string: transactionUrl) else {
            print("Invalid transaction URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add cookies to header (using the first cookie in case of duplicates)
        if let deviceIdCookie = cookieMap["revo_device_id"]?.first {
            request.setValue(deviceIdCookie.value, forHTTPHeaderField: "x-device-id")
        }

        // Add User-Agent
        let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36"
        request.setValue(userAgent, forHTTPHeaderField: "user-agent")
        
        // Set cookies in the request header
        let cookieHeader = createCookieHeader(from: cookieMap)
        request.setValue(cookieHeader, forHTTPHeaderField: "cookie")

        performNetworkRequest(with: request)
    }

    // Create the cookie header by joining cookies into a single string
    private func createCookieHeader(from cookies: [String: [HTTPCookie]]) -> String {
        return cookies.flatMap { $0.value.map { "\($0.name)=\($0.value)" } }
                      .joined(separator: "; ")
    }


    // MARK: - Network Request
    private func performNetworkRequest(with request: URLRequest) {
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request failed with error: \(error.localizedDescription)")
                return
            }

            if let response = response as? HTTPURLResponse {
                print("Response status code: \(response.statusCode)")
            }

            if let data = data {
                self.handleResponseData(data)
            }
        }
        task.resume()
    }

    private func handleResponseData(_ data: Data) {
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response data: \(responseString)")
        }
    }
    
}

// MARK: - WebViewControllerRepresentable
struct RevolutViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> RevolutViewController {
        return RevolutViewController()
    }

    func updateUIViewController(_ uiViewController: RevolutViewController, context: Context) {
        // Update the WebViewController if needed
    }
}

struct RevolutView: View {
    var body: some View {
        RevolutViewControllerRepresentable()
    }
}

// MARK: - Preview
#Preview {
    RevolutViewControllerRepresentable()
        .edgesIgnoringSafeArea(.all)
}

