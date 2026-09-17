#!/usr/bin/env bash
# ============================================================
#  BUDGET MANAGER APK - PROJECT FILES CREATOR
# ============================================================
#  Ye script GitHub Actions par chalta hai aur ise chala kar
#  poora Android WebView project + APK builder workflow ban jata hai.
#
#  Iske andar aapki website ka code NAHI hai - sirf ek Android shell
#  app hai jo aapki live GitHub Pages website ko kholta hai.
# ============================================================

set -euo pipefail

echo "=============================================="
echo " Android WebView project banaya ja raha hai..."
echo "=============================================="

mkdir -p android/app/src/main/java/com/pappuyadav/personalbudget
mkdir -p android/app/src/main/res/values
mkdir -p android/app/src/main/res/drawable
mkdir -p .github/workflows

# Purana workflow file (agar pehle se repo me pada ho) hata do -
# ab APK banane ka poora kaam .github/workflows/build-apk.yml akela karta hai.
rm -f .github/workflows/create-project-files.yml

# ---------- 1) android/.gitignore ----------
# Gradle junk ignore list
echo '  [1/13] android/.gitignore'
cat > android/.gitignore <<'###_PB_EOF_1_###'
# Gradle / Android build ke temporary files
# (in files ko repo me upload karne ki zarurat nahi - Actions me khud ban jati hain)
.gradle/
build/
app/build/
local.properties
captures/
*.iml
.idea/
.DS_Store
###_PB_EOF_1_###

# ---------- 2) android/settings.gradle ----------
# Gradle settings
echo '  [2/13] android/settings.gradle'
cat > android/settings.gradle <<'###_PB_EOF_2_###'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "PersonalBudget"
include ':app'
###_PB_EOF_2_###

# ---------- 3) android/build.gradle ----------
# Android plugin version
echo '  [3/13] android/build.gradle'
cat > android/build.gradle <<'###_PB_EOF_3_###'
// Top-level build file - yahan sirf Android plugin ka version set hota hai
plugins {
    id 'com.android.application' version '8.4.0' apply false
}

tasks.register('clean', Delete) {
    delete rootProject.layout.buildDirectory
}
###_PB_EOF_3_###

# ---------- 4) android/gradle.properties ----------
# Build memory settings
echo '  [4/13] android/gradle.properties'
cat > android/gradle.properties <<'###_PB_EOF_4_###'
# Build ki speed / memory settings
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
org.gradle.daemon=false
org.gradle.parallel=true
org.gradle.caching=true

# Is app me koi external library (AndroidX) use nahi hoti - build fast aur halka rehta hai
android.useAndroidX=false
android.nonTransitiveRClass=true
###_PB_EOF_4_###

# ---------- 5) android/app/build.gradle ----------
# App module config (minSdk 23, targetSdk 34)
echo '  [5/13] android/app/build.gradle'
cat > android/app/build.gradle <<'###_PB_EOF_5_###'
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.pappuyadav.personalbudget'
    compileSdk 34

    defaultConfig {
        applicationId 'com.pappuyadav.personalbudget'
        minSdk 23              // Android 6.0 se lekar latest tak sab phones par chalega
        targetSdk 34
        versionCode 1
        versionName '1.0'
    }

    buildTypes {
        debug {
            // Test karne ke liye debug APK hi kaafi hai (direct install hota hai)
            debuggable true
        }
        release {
            // Play Store ke liye baad me release + signing add kar sakte hain
            minifyEnabled false
            shrinkResources false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    lint {
        // Chhoti warnings se build rukna nahi chahiye
        abortOnError false
        checkReleaseBuilds false
    }

    packagingOptions {
        resources {
            excludes += ['META-INF/*.kotlin_module', 'META-INF/*.version']
        }
    }
}

// NOTE: koi bhi external library (AndroidX / browser / ads) use nahi ki gayi -
// APK chhota (lagbhag 1 MB) rehta hai aur offline-verified code hi chalta hai.
dependencies { }
###_PB_EOF_5_###

# ---------- 6) android/app/proguard-rules.pro ----------
# Proguard rules (khali)
echo '  [6/13] android/app/proguard-rules.pro'
cat > android/app/proguard-rules.pro <<'###_PB_EOF_6_###'
# Is app me minifyEnabled false hai, isliye abhi koi rule zaruri nahi.
# Agar kabhi release build me minify on karein to yahan rules add karein.
###_PB_EOF_6_###

# ---------- 7) android/app/src/main/AndroidManifest.xml ----------
# Internet permission + WebView activity
echo '  [7/13] android/app/src/main/AndroidManifest.xml'
cat > android/app/src/main/AndroidManifest.xml <<'###_PB_EOF_7_###'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Internet ke bina data sync nahi hoga -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:allowBackup="true"
        android:hardwareAccelerated="true"
        android:icon="@drawable/ic_launcher"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:usesCleartextTraffic="false"
        android:theme="@style/Theme.PersonalBudget">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTask"
            android:configChanges="keyboardHidden|orientation|screenSize|smallestScreenSize|screenLayout|uiMode|density|fontScale|layoutDirection|locale"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
###_PB_EOF_7_###

# ---------- 8) android/app/src/main/java/com/pappuyadav/personalbudget/MainActivity.java ----------
# WebView engine + Back button logic
echo '  [8/13] android/app/src/main/java/com/pappuyadav/personalbudget/MainActivity.java'
cat > android/app/src/main/java/com/pappuyadav/personalbudget/MainActivity.java <<'###_PB_EOF_8_###'
package com.pappuyadav.personalbudget;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.webkit.CookieManager;
import android.webkit.JsResult;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

/**
 * Personal Budget Manager - Android WebView shell.
 *
 * Ye app aapki LIVE website ko WebView me kholta hai, isliye:
 *   - UI, saare features aur Google Apps Script + Google Sheets backend
 *     exactly wahi rehta hai jo website par hai (kuch modify nahi hota).
 *   - Website me aap jo bhi update karenge, app me turant dikhega.
 */
public class MainActivity extends Activity {

    /** Website ka live URL (GitHub Pages) - ye badalne ki zarurat nahi. */
    private static final String APP_URL =
            "https://pappuyadav80800.github.io/MY_Personal_budget/";

    /** Website ke CSS variable --bg-main ka rang (white flash se bachne ke liye). */
    private static final int BG_COLOR = 0xFFEDF2F7;

    /** Back button do baar dabane ka time (ms). */
    private static final long DOUBLE_BACK_MS = 2000L;

    /**
     * Back button ka dimaag (page ke andar hi decide hota hai):
     *   1) Login screen khuli hai           -> "EXIT"    (app band karne ka flow)
     *   2) Dashboard ke alawa koi tab khula -> "HANDLED" (Dashboard par wapas)
     *   3) Dashboard khula hai              -> "EXIT"
     */
    private static final String BACK_JS =
            "(function(){try{" +
            "var lo=document.getElementById('loginOverlay');" +
            "if(lo && !lo.classList.contains('hidden')){return 'EXIT';}" +
            "var t=document.querySelector('.tab-content.active');" +
            "if(t && t.id && t.id!=='tab-dashboard'){window.switchTab('dashboard');return 'HANDLED';}" +
            "return 'EXIT';}catch(e){return 'EXIT';}})()";

    private WebView      webView;
    private LinearLayout errorView;
    private boolean      loadFailed    = false;
    private long         lastBackPress = 0L;

    // ============================================================
    // LIFECYCLE
    // ============================================================
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(BG_COLOR);

        webView = new WebView(this);
        webView.setBackgroundColor(BG_COLOR);
        root.addView(webView, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));

        errorView = buildErrorView();
        root.addView(errorView, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));

        setContentView(root);

        configureWebView();

        if (savedInstanceState != null) {
            webView.restoreState(savedInstanceState);
            if (webView.getUrl() == null) webView.loadUrl(APP_URL);
        } else {
            webView.loadUrl(APP_URL);
        }
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        if (webView != null) webView.saveState(outState);
    }

    @Override
    protected void onDestroy() {
        if (webView != null) {
            webView.stopLoading();
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }

    // ============================================================
    // WEBVIEW SETTINGS - website ke saare features chalane ke liye
    // ============================================================
    @SuppressLint("SetJavaScriptEnabled")
    private void configureWebView() {
        WebSettings s = webView.getSettings();

        // 1) JavaScript - app ka pura logic JS me hai
        s.setJavaScriptEnabled(true);

        // 2) localStorage / sessionStorage - login state + data cache
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);

        // 3) Cookies - Google endpoints ke liye
        CookieManager cm = CookieManager.getInstance();
        cm.setAcceptCookie(true);
        cm.setAcceptThirdPartyCookies(webView, true);

        // 4) Network se sab kuch load ho (HTML/CSS/JS/images)
        s.setLoadsImagesAutomatically(true);
        s.setBlockNetworkImage(false);
        s.setBlockNetworkLoads(false);

        // 5) Local file access ki zarurat nahi (security ke liye off)
        s.setAllowFileAccess(false);
        s.setAllowContentAccess(false);

        // 6) Google Apps Script ka JSONP (<script src=".../exec?callback=...">)
        //    isi tarah data load hota hai - isliye JS window open + mixed content allowed
        s.setJavaScriptCanOpenWindowsAutomatically(true);
        s.setMixedContentMode(WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE);
        s.setCacheMode(WebSettings.LOAD_DEFAULT);

        // 7) Responsive / mobile-friendly view
        s.setUseWideViewPort(true);
        s.setLoadWithOverviewMode(true);
        s.setSupportZoom(false);
        s.setBuiltInZoomControls(false);
        s.setTextZoom(100);                 // phone ke font setting se layout na bigde
        s.setMediaPlaybackRequiresUserGesture(true);

        // WebViewClient -> links + error handling
        webView.setWebViewClient(new AppWebViewClient());

        // WebChromeClient -> site ke confirm()/alert() dialogs
        // (Logout aur Delete Entry inhi par depend karte hain - iske bina wo kaam nahi karenge)
        webView.setWebChromeClient(new AppChromeClient());

        webView.setOverScrollMode(View.OVER_SCROLL_NEVER);
        webView.setVerticalScrollBarEnabled(false);
        webView.setHorizontalScrollBarEnabled(false);
    }

    // ============================================================
    // JS DIALOGS (alert / confirm) - apne dialog, bina kisi URL ke
    // ============================================================
    /**
     * Website ke confirm()/alert() ke liye apna Android dialog.
     *
     * Kyun zaruri hai: Android ka default WebView dialog apne title me
     * page ka URL dikha deta hai ("The page at https://... says:").
     * Apna AlertDialog use karne se screen par koi URL/address nahi dikhta,
     * aur website ka code (logout, delete entry) pehle jaisa hi chalta rehta hai.
     *
     * Note: website me prompt() kahin use nahi hota, isliye usko handle nahi kiya gaya.
     */
    private class AppChromeClient extends WebChromeClient {

        @Override
        public boolean onJsAlert(WebView view, String url, String message, JsResult result) {
            new AlertDialog.Builder(MainActivity.this)
                    .setTitle(R.string.app_name)
                    .setMessage(message)
                    .setPositiveButton("OK", (dialog, which) -> result.confirm())
                    .setOnCancelListener(dialog -> result.confirm())
                    .show();
            return true;
        }

        @Override
        public boolean onJsConfirm(WebView view, String url, String message, JsResult result) {
            new AlertDialog.Builder(MainActivity.this)
                    .setTitle(R.string.app_name)
                    .setMessage(message)
                    .setPositiveButton("OK", (dialog, which) -> result.confirm())
                    .setNegativeButton("Cancel", (dialog, which) -> result.cancel())
                    .setOnCancelListener(dialog -> result.cancel())
                    .show();
            return true;
        }
    }

    // ============================================================
    // LINKS + ERROR SCREEN
    // ============================================================
    private class AppWebViewClient extends WebViewClient {

        @Override
        public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
            return openUrl(view, request.getUrl());
        }

        @SuppressWarnings("deprecation")
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            return openUrl(view, Uri.parse(url));
        }

        @Override
        public void onPageStarted(WebView view, String url, Bitmap favicon) {
            loadFailed = false;
        }

        @Override
        public void onPageFinished(WebView view, String url) {
            if (!loadFailed) errorView.setVisibility(View.GONE);
            // Browser jaisi history app me nahi chahiye - back button ka kaam
            // BACK_JS se control hota hai (guess-work nahi).
            view.clearHistory();
        }

        @Override
        public void onReceivedError(WebView view, WebResourceRequest request,
                                    WebResourceError error) {
            if (request != null && request.isForMainFrame()) {
                loadFailed = true;
                errorView.setVisibility(View.VISIBLE);
            }
        }

        @SuppressWarnings("deprecation")
        @Override
        public void onReceivedError(WebView view, int errorCode, String description,
                                    String failingUrl) {
            if (failingUrl != null && failingUrl.startsWith(APP_URL)) {
                loadFailed = true;
                errorView.setVisibility(View.VISIBLE);
            }
        }
    }

    /**
     * App ke apne hosts WebView ke andar khulte hain; baaki saare links
     * (Gmail, WhatsApp, koi bhi bahar ka link) phone ke browser/app me khulte hain.
     */
    private boolean openUrl(WebView view, Uri uri) {
        if (uri == null) return false;

        String scheme = uri.getScheme() == null ? "" : uri.getScheme().toLowerCase();
        String host   = uri.getHost()   == null ? "" : uri.getHost().toLowerCase();

        boolean keepInside = "https".equals(scheme) && (
                    host.endsWith("github.io")                    ||
                    host.endsWith("script.google.com")            ||
                    host.endsWith("script.googleusercontent.com") ||
                    host.endsWith("google.com")                   ||
                    host.endsWith("googleapis.com"));

        if (keepInside) return false;   // WebView me hi load hone do

        try {
            view.getContext().startActivity(new Intent(Intent.ACTION_VIEW, uri));
        } catch (ActivityNotFoundException e) {
            Toast.makeText(this, "No app found to open this link", Toast.LENGTH_SHORT).show();
        }
        return true;
    }

    // ============================================================
    // "NO INTERNET" SCREEN (Retry button ke saath)
    // ============================================================
    private LinearLayout buildErrorView() {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setGravity(Gravity.CENTER);
        box.setBackgroundColor(BG_COLOR);
        box.setPadding(60, 60, 60, 60);
        box.setVisibility(View.GONE);

        TextView title = new TextView(this);
        title.setText("No Internet Connection");
        title.setTextSize(20f);
        title.setTextColor(Color.parseColor("#0B2545"));
        title.setGravity(Gravity.CENTER);

        TextView msg = new TextView(this);
        msg.setText("Please check your internet and try again.");
        msg.setTextSize(14f);
        msg.setTextColor(Color.parseColor("#64748B"));
        msg.setGravity(Gravity.CENTER);
        msg.setPadding(0, 20, 0, 40);

        Button retry = new Button(this);
        retry.setText("Try Again");
        retry.setAllCaps(false);
        retry.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                errorView.setVisibility(View.GONE);
                loadFailed = false;
                webView.loadUrl(APP_URL);
            }
        });

        box.addView(title);
        box.addView(msg);
        box.addView(retry);
        return box;
    }

    // ============================================================
    // ANDROID BACK BUTTON
    // ============================================================
    @Override
    public void onBackPressed() {
        if (webView == null || webView.getUrl() == null) {
            super.onBackPressed();
            return;
        }

        webView.evaluateJavascript(BACK_JS, value -> {
            String result = (value == null) ? "EXIT" : value.replace("\"", "");
            if ("HANDLED".equals(result)) {
                lastBackPress = 0L;          // app ke andar navigate hua, exit nahi
            } else {
                handleExit();
            }
        });
    }

    private void handleExit() {
        long now = System.currentTimeMillis();
        if (now - lastBackPress < DOUBLE_BACK_MS) {
            lastBackPress = 0L;
            finish();                        // app band
        } else {
            lastBackPress = now;
            Toast.makeText(this, "Press Back again to exit", Toast.LENGTH_SHORT).show();
        }
    }
}
###_PB_EOF_8_###

# ---------- 9) android/app/src/main/res/values/strings.xml ----------
# App ka naam
echo '  [9/13] android/app/src/main/res/values/strings.xml'
cat > android/app/src/main/res/values/strings.xml <<'###_PB_EOF_9_###'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Phone ke home screen / app drawer me ye naam dikhega -->
    <string name="app_name">Budget Manager</string>
</resources>
###_PB_EOF_9_###

# ---------- 10) android/app/src/main/res/values/colors.xml ----------
# Website ke rang
echo '  [10/13] android/app/src/main/res/values/colors.xml'
cat > android/app/src/main/res/values/colors.xml <<'###_PB_EOF_10_###'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Ye rang aapki website ke CSS variables se liye gaye hain -->
    <color name="bg_main">#EDF2F7</color>      <!-- main background -->
    <color name="navy_deep">#0B2545</color>    <!-- header navy (gradient ka pehla rang) -->
    <color name="gold_accent">#FBBF24</color>  <!-- gold accent -->
</resources>
###_PB_EOF_10_###

# ---------- 11) android/app/src/main/res/values/themes.xml ----------
# Theme (navy status bar)
echo '  [11/13] android/app/src/main/res/values/themes.xml'
cat > android/app/src/main/res/values/themes.xml <<'###_PB_EOF_11_###'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!--
      Website ke look se match karta hua theme:
      navy status bar + halka (#edf2f7) background - isliye app khulte waqt
      white flash nahi dikhta, sidha website ka background feel aata hai.
    -->
    <style name="Theme.PersonalBudget" parent="@android:style/Theme.Material.Light.NoActionBar">
        <item name="android:windowBackground">@color/bg_main</item>
        <item name="android:statusBarColor">@color/navy_deep</item>
        <item name="android:navigationBarColor">@color/bg_main</item>
        <item name="android:windowLightStatusBar">false</item>
        <item name="android:windowLightNavigationBar">true</item>
        <item name="android:colorAccent">@color/gold_accent</item>
    </style>
</resources>
###_PB_EOF_11_###

# ---------- 12) android/app/src/main/res/drawable/ic_launcher.xml ----------
# App icon (navy + gold)
echo '  [12/13] android/app/src/main/res/drawable/ic_launcher.xml'
cat > android/app/src/main/res/drawable/ic_launcher.xml <<'###_PB_EOF_12_###'
<?xml version="1.0" encoding="utf-8"?>
<!--
  App icon - website ke navy + gold rang me banaya gaya.
  Baad me chahein to apni PNG icon se replace kar sakte hain.
-->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">

    <!-- Navy background -->
    <path
        android:fillColor="#0B2545"
        android:pathData="M0,0h108v108h-108z" />

    <!-- Gold "rupee" symbol -->
    <path
        android:fillColor="#FBBF24"
        android:pathData="M39,27h30v9h-12.2c4.4,2.2 7.2,6.4 7.2,11.4c0,7.6 -5.6,12.8 -13.4,13.4l14.6,20.2h-11.4l-14.2,-20.2h-3.6v-8.4h9.2c5.6,0 9.4,-2.8 9.4,-6.8c0,-3.4 -2.6,-5.8 -7.2,-5.8h-4.4v-8.4h13.2z" />
</vector>
###_PB_EOF_12_###

# ---------- 13) .github/workflows/build-apk.yml ----------
# APK banane + release karne wala workflow
echo '  [13/13] .github/workflows/build-apk.yml'
cat > .github/workflows/build-apk.yml <<'###_PB_EOF_13_###'
name: Build APK

# Is repo me kuch bhi upload karte hi ye file apne aap chalti hai
# aur APK bana kar "Releases" me download link de deti hai.
# Manual chalane ke liye: Actions tab > Build APK > Run workflow
on:
  push:
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
      - name: 1) Code checkout
        uses: actions/checkout@v4

      - name: 2) Android project files banao
        run: |
          if [ ! -f Create-Files.sh ]; then
            echo "Create-Files.sh repo me nahi mila - pehle use upload karein."
            exit 1
          fi
          bash Create-Files.sh

      - name: 3) Java 17 setup
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: 4) Android SDK setup
        uses: android-actions/setup-android@v3

      - name: 5) Gradle 8.7 setup
        uses: gradle/actions/setup-gradle@v4
        with:
          gradle-version: '8.7'

      - name: 6) APK build
        working-directory: android
        run: |
          echo "sdk.dir=$ANDROID_HOME" > local.properties
          SDKM="$(command -v sdkmanager || true)"
          if [ -z "$SDKM" ] && [ -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
            SDKM="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
          fi
          if [ -n "$SDKM" ]; then
            yes | "$SDKM" --licenses > /dev/null 2>&1 || true
            "$SDKM" "platforms;android-34" "build-tools;34.0.0" > /dev/null 2>&1 || true
          fi
          gradle --no-daemon assembleDebug

      - name: 7) APK ka download link banao
        continue-on-error: true
        uses: softprops/action-gh-release@v2
        with:
          tag_name: apk-latest
          name: Budget Manager APK (latest)
          body: |
            Ready APK - phone me install karein.
            (Settings me "Install unknown apps" allow karna hoga.)
          files: android/app/build/outputs/apk/debug/app-debug.apk

      - name: 8) Backup - APK run ke andar bhi
        uses: actions/upload-artifact@v4
        with:
          name: BudgetManager-apk
          path: android/app/build/outputs/apk/debug/app-debug.apk
          if-no-files-found: error
###_PB_EOF_13_###

echo ""
echo "=============================================="
echo " SUCCESS: Saari files ban gayi!"
echo "=============================================="
echo ""
echo "Banayi gayi files:"
find android .github -type f | sort

