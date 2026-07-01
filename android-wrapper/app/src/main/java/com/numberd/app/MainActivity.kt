package com.numberd.app

import android.annotation.SuppressLint
import android.app.DownloadManager
import android.content.Context
import android.content.IntentFilter
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.view.View
import android.view.ViewGroup
import android.webkit.CookieManager
import android.webkit.DownloadListener
import android.webkit.URLUtil
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.WindowCompat
import com.numberd.app.ui.theme.NumberDTheme

class MainActivity : ComponentActivity() {

    private val targetUrl = "https://numberd-seven.vercel.app/"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Handle the splash screen transition.
        installSplashScreen()
        
        super.onCreate(savedInstanceState)
        
        // Disable decor fitting system windows to draw behind status bar and navigation bar
        WindowCompat.setDecorFitsSystemWindows(window, false)

        setContent {
            NumberDTheme {
                NumberDAppWrapper(targetUrl = targetUrl)
            }
        }
    }
}

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun NumberDAppWrapper(targetUrl: String) {
    var webViewRef by remember { mutableStateOf<WebView?>(null) }
    var isError by remember { mutableStateOf(false) }

    var customView by remember { mutableStateOf<View?>(null) }
    var customViewCallback by remember { mutableStateOf<WebChromeClient.CustomViewCallback?>(null) }

    // Intercept hardware back button
    BackHandler(enabled = (webViewRef?.canGoBack() == true || customView != null) && !isError) {
        if (customView != null) {
            // Handle exiting fullscreen
            customViewCallback?.onCustomViewHidden()
            customView = null
            customViewCallback = null
        } else {
            webViewRef?.goBack()
        }
    }

    if (isError) {
        OfflineFallback(onRetry = {
            isError = false
            webViewRef?.reload()
        })
    } else {
        Box(modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0F0F14))
        ) {
            Box(modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
            ) {
                AndroidView(
                    modifier = Modifier.fillMaxSize(),
                    factory = { context ->
                        WebView(context).apply {
                            layoutParams = ViewGroup.LayoutParams(
                                ViewGroup.LayoutParams.MATCH_PARENT,
                                ViewGroup.LayoutParams.MATCH_PARENT
                            )
                            
                            // Set web background to app background color
                            setBackgroundColor(android.graphics.Color.parseColor("#0f0f14"))

                            settings.apply {
                                javaScriptEnabled = true
                                domStorageEnabled = true
                                databaseEnabled = true
                                allowFileAccess = true
                                mixedContentMode = android.webkit.WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
                                loadsImagesAutomatically = true
                                useWideViewPort = true
                                loadWithOverviewMode = true
                                setSupportMultipleWindows(true)
                                javaScriptCanOpenWindowsAutomatically = true
                            }

                            // Web Chrome Client for hardware acceleration, console, JS alerts, and FULLSCREEN
                            webChromeClient = object : WebChromeClient() {
                                override fun onShowCustomView(view: View?, callback: CustomViewCallback?) {
                                    super.onShowCustomView(view, callback)
                                    customView = view
                                    customViewCallback = callback
                                }

                                override fun onHideCustomView() {
                                    super.onHideCustomView()
                                    customView = null
                                    customViewCallback = null
                                }
                            }

                            // Web View Client to prevent launching external browser and handle errors
                            webViewClient = object : WebViewClient() {
                                override fun onReceivedError(
                                    view: WebView?,
                                    request: WebResourceRequest?,
                                    error: WebResourceError?
                                ) {
                                    super.onReceivedError(view, request, error)
                                    if (request?.isForMainFrame == true) {
                                        isError = true
                                    }
                                }
                            }

                            // Attach DownloadManager for exporting CSV/JSON
                            setDownloadListener { url, userAgent, contentDisposition, mimetype, contentLength ->
                                val request = DownloadManager.Request(Uri.parse(url)).apply {
                                    setMimeType(mimetype)
                                    val cookies = CookieManager.getInstance().getCookie(url)
                                    addRequestHeader("cookie", cookies)
                                    addRequestHeader("User-Agent", userAgent)
                                    setTitle(URLUtil.guessFileName(url, contentDisposition, mimetype))
                                    allowScanningByMediaScanner()
                                    setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                                    setDestinationInExternalPublicDir(
                                        Environment.DIRECTORY_DOWNLOADS,
                                        URLUtil.guessFileName(url, contentDisposition, mimetype)
                                    )
                                }
                                val dm = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
                                dm.enqueue(request)
                                Toast.makeText(context, "Downloading file...", Toast.LENGTH_LONG).show()
                            }

                            webViewRef = this
                            loadUrl(targetUrl)
                        }
                    },
                    update = { webView ->
                        webViewRef = webView
                    }
                )
            }

            // Overlay for fullscreen video
            if (customView != null) {
                AndroidView(
                    modifier = Modifier.fillMaxSize().background(Color.Black),
                    factory = { context ->
                        FrameLayout(context).apply {
                            addView(customView)
                        }
                    }
                )
            }
        }
    }
}

@Composable
fun OfflineFallback(onRetry: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0F0F14)),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        val gradient = Brush.linearGradient(
            colors = listOf(Color(0xFF7C3AED), Color(0xFFD946EF))
        )
        
        Box(
            modifier = Modifier
                .size(80.dp)
                .background(gradient, shape = RoundedCornerShape(16.dp)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                painter = painterResource(id = R.drawable.ic_numberd_logo),
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = Color.White
            )
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text(
            text = "No Internet Connection",
            color = Color.White,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "Please check your network and try again.",
            color = Color.Gray,
            fontSize = 14.sp
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        Button(
            onClick = onRetry,
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF7C3AED)),
            shape = RoundedCornerShape(8.dp),
            modifier = Modifier.padding(horizontal = 32.dp).height(48.dp)
        ) {
            Text("Retry Connection", color = Color.White, fontWeight = FontWeight.Medium)
        }
    }
}
