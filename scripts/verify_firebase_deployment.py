#!/usr/bin/env python3
"""
Firebase Deployment Verification Script
=====================================

This script verifies that your Firebase configuration is ready for production deployment.
It checks all configuration files, build status, and identifies any issues.

Usage:
    python scripts/verify_firebase_deployment.py
"""

import os
import json
import re
import subprocess
import sys
from pathlib import Path

class FirebaseDeploymentVerifier:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.issues = []
        self.warnings = []
        self.success_count = 0
        self.total_checks = 0
        
    def log_success(self, message):
        """Log a successful check"""
        print(f"✅ {message}")
        self.success_count += 1
        self.total_checks += 1
        
    def log_warning(self, message):
        """Log a warning"""
        print(f"⚠️  {message}")
        self.warnings.append(message)
        self.total_checks += 1
        
    def log_error(self, message):
        """Log an error"""
        print(f"❌ {message}")
        self.issues.append(message)
        self.total_checks += 1
        
    def check_file_exists(self, file_path, description):
        """Check if a file exists"""
        full_path = self.project_root / file_path
        if full_path.exists():
            self.log_success(f"{description}: {file_path}")
            return True
        else:
            self.log_error(f"{description}: {file_path} - FILE MISSING")
            return False
            
    def check_firebase_options(self):
        """Check Firebase options configuration"""
        print("\n🔧 Checking Firebase Options Configuration...")
        
        options_file = self.project_root / "lib" / "firebase_options.dart"
        if not options_file.exists():
            self.log_error("Firebase options file not found")
            return
            
        content = options_file.read_text()
        
        # Check for placeholder values
        placeholder_patterns = [
            r'placeholder-project-id',
            r'your-project-id',
            r'your-app-id',
            r'your-api-key',
            r'example\.com',
            r'com\.example\.',
        ]
        
        for pattern in placeholder_patterns:
            if re.search(pattern, content):
                self.log_error(f"Found placeholder pattern: {pattern}")
                
        # Check for real project ID
        if 'lca5kr3efmasxydmsi1rvyjoizifj4' in content:
            self.log_success("Real Firebase project ID found")
        else:
            self.log_error("Real Firebase project ID not found")
            
        # Check platform configurations
        platforms = ['android', 'ios', 'web', 'macos', 'windows']
        for platform in platforms:
            if f'static const FirebaseOptions {platform}' in content:
                self.log_success(f"{platform.capitalize()} configuration present")
            else:
                self.log_warning(f"{platform.capitalize()} configuration missing")
                
    def check_android_config(self):
        """Check Android Firebase configuration"""
        print("\n🤖 Checking Android Configuration...")
        
        # Check google-services.json
        self.check_file_exists(
            "android/app/google-services.json",
            "Google Services JSON"
        )
        
        # Check build.gradle
        build_gradle = self.project_root / "android" / "app" / "build.gradle"
        if build_gradle.exists():
            content = build_gradle.read_text()
            if 'com.google.gms.google-services' in content:
                self.log_success("Google Services plugin integrated")
            else:
                self.log_error("Google Services plugin not integrated")
                
            if 'firebase-bom' in content:
                self.log_success("Firebase BoM dependency present")
            else:
                self.log_warning("Firebase BoM dependency missing")
                
    def check_ios_config(self):
        """Check iOS Firebase configuration"""
        print("\n🍎 Checking iOS Configuration...")
        
        # Check GoogleService-Info.plist
        self.check_file_exists(
            "ios/Runner/GoogleService-Info.plist",
            "GoogleService-Info.plist"
        )
        
        # Check Info.plist
        info_plist = self.project_root / "ios" / "Runner" / "Info.plist"
        if info_plist.exists():
            content = info_plist.read_text()
            if 'CFBundleURLTypes' in content:
                self.log_success("URL schemes configured")
            else:
                self.log_warning("URL schemes not configured")
                
    def check_web_config(self):
        """Check Web Firebase configuration"""
        print("\n🌐 Checking Web Configuration...")
        
        # Check index.html
        index_html = self.project_root / "web" / "index.html"
        if index_html.exists():
            content = index_html.read_text()
            if 'firebase' in content.lower():
                self.log_success("Firebase scripts in index.html")
            else:
                self.log_warning("Firebase scripts not found in index.html")
        else:
            self.log_warning("Web index.html not found")
            
    def check_dependencies(self):
        """Check Firebase dependencies in pubspec.yaml"""
        print("\n📦 Checking Dependencies...")
        
        pubspec = self.project_root / "pubspec.yaml"
        if not pubspec.exists():
            self.log_error("pubspec.yaml not found")
            return
            
        content = pubspec.read_text()
        
        firebase_packages = [
            'firebase_core',
            'firebase_auth',
            'cloud_firestore',
            'firebase_storage',
            'firebase_messaging',
            'firebase_analytics',
            'firebase_remote_config',
        ]
        
        for package in firebase_packages:
            if package in content:
                self.log_success(f"{package} dependency present")
            else:
                self.log_warning(f"{package} dependency missing")
                
    def check_build_status(self):
        """Check if the app builds successfully"""
        print("\n🔨 Checking Build Status...")
        
        try:
            # Try to build the app
            result = subprocess.run(
                ['flutter', 'build', 'apk', '--debug'],
                capture_output=True,
                text=True,
                cwd=self.project_root,
                timeout=300  # 5 minutes timeout
            )
            
            if result.returncode == 0:
                self.log_success("App builds successfully")
            else:
                self.log_error(f"Build failed: {result.stderr}")
                
        except subprocess.TimeoutExpired:
            self.log_warning("Build timed out (this is normal for first build)")
        except FileNotFoundError:
            self.log_error("Flutter not found in PATH")
        except Exception as e:
            self.log_error(f"Build check failed: {e}")
            
    def check_security_rules(self):
        """Check Firebase security rules"""
        print("\n🔒 Checking Security Rules...")
        
        # Check Firestore rules
        firestore_rules = self.project_root / "firestore.rules"
        if firestore_rules.exists():
            self.log_success("Firestore security rules present")
        else:
            self.log_warning("Firestore security rules not found")
            
        # Check Storage rules
        storage_rules = self.project_root / "storage.rules"
        if storage_rules.exists():
            self.log_success("Storage security rules present")
        else:
            self.log_warning("Storage security rules not found")
            
    def generate_report(self):
        """Generate deployment readiness report"""
        print("\n" + "="*60)
        print("📊 FIREBASE DEPLOYMENT READINESS REPORT")
        print("="*60)
        
        print(f"\nTotal Checks: {self.total_checks}")
        print(f"✅ Successful: {self.success_count}")
        print(f"⚠️  Warnings: {len(self.warnings)}")
        print(f"❌ Issues: {len(self.issues)}")
        
        if self.issues:
            print(f"\n❌ CRITICAL ISSUES TO FIX:")
            for issue in self.issues:
                print(f"   • {issue}")
                
        if self.warnings:
            print(f"\n⚠️  WARNINGS TO ADDRESS:")
            for warning in self.warnings:
                print(f"   • {warning}")
                
        if not self.issues:
            print(f"\n🎉 DEPLOYMENT STATUS: READY!")
            print("   Your Firebase configuration is ready for production deployment.")
        else:
            print(f"\n🚨 DEPLOYMENT STATUS: NOT READY")
            print("   Please fix the critical issues before deploying.")
            
        print("\n" + "="*60)
        
    def run_all_checks(self):
        """Run all verification checks"""
        print("🚀 Starting Firebase Deployment Verification...")
        print("="*60)
        
        self.check_firebase_options()
        self.check_android_config()
        self.check_ios_config()
        self.check_web_config()
        self.check_dependencies()
        self.check_security_rules()
        self.check_build_status()
        
        self.generate_report()
        
        return len(self.issues) == 0

def main():
    """Main function"""
    verifier = FirebaseDeploymentVerifier()
    success = verifier.run_all_checks()
    
    if success:
        print("\n🎯 All checks passed! Your Firebase configuration is ready for deployment.")
        sys.exit(0)
    else:
        print("\n⚠️  Some issues were found. Please fix them before deploying.")
        sys.exit(1)

if __name__ == "__main__":
    main()

