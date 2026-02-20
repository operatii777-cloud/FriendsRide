#!/usr/bin/env python3
"""
Continuous Monitoring System for FriendsRide Diagnostic
Monitors code quality, performance, and security metrics continuously
"""

import json
import os
import subprocess
import time
from datetime import datetime, timedelta
from typing import Dict, List, Any
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('diagnostic_monitoring.log'),
        logging.StreamHandler()
    ]
)

class DiagnosticMonitor:
    def __init__(self, project_path: str):
        self.project_path = project_path
        self.metrics_file = 'diagnostic_metrics.json'
        self.baseline_file = 'diagnostic_baseline.json'
        self.alert_thresholds = {
            'overall_score': 70,
            'security_score': 70,
            'performance_score': 70,
            'code_quality_score': 70,
            'test_coverage': 30
        }
        
    def load_baseline(self) -> Dict[str, Any]:
        """Load baseline metrics for comparison"""
        try:
            with open(self.baseline_file, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            logging.warning("Baseline file not found. Creating new baseline.")
            return {}
    
    def save_baseline(self, metrics: Dict[str, Any]):
        """Save current metrics as new baseline"""
        with open(self.baseline_file, 'w') as f:
            json.dump(metrics, f, indent=2)
        logging.info("Baseline updated successfully.")
    
    def run_flutter_analyze(self) -> Dict[str, Any]:
        """Run flutter analyze and parse results"""
        try:
            result = subprocess.run(
                ['flutter', 'analyze'],
                cwd=self.project_path,
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.returncode == 0:
                return {
                    'status': 'success',
                    'errors': 0,
                    'warnings': 0,
                    'info': 0,
                    'score': 100
                }
            else:
                # Parse flutter analyze output
                output = result.stdout + result.stderr
                errors = output.count('error')
                warnings = output.count('warning')
                info = output.count('info')
                
                # Calculate score based on issues
                total_issues = errors + warnings + info
                if total_issues == 0:
                    score = 100
                else:
                    score = max(0, 100 - (errors * 10) - (warnings * 5) - info)
                
                return {
                    'status': 'issues_found',
                    'errors': errors,
                    'warnings': warnings,
                    'info': info,
                    'score': score
                }
                
        except subprocess.TimeoutExpired:
            logging.error("Flutter analyze timed out")
            return {'status': 'timeout', 'score': 0}
        except Exception as e:
            logging.error(f"Error running flutter analyze: {e}")
            return {'status': 'error', 'score': 0}
    
    def check_test_coverage(self) -> Dict[str, Any]:
        """Check test coverage if available"""
        try:
            # This would require actual test coverage data
            # For now, return estimated coverage
            test_files = len([f for f in os.listdir(f"{self.project_path}/test") 
                            if f.endswith('_test.dart')])
            estimated_coverage = min(100, test_files * 5)  # Rough estimate
            
            return {
                'unit_tests': test_files,
                'estimated_coverage': estimated_coverage,
                'score': estimated_coverage
            }
        except Exception as e:
            logging.error(f"Error checking test coverage: {e}")
            return {'score': 0}
    
    def check_security_issues(self) -> Dict[str, Any]:
        """Check for common security issues"""
        security_score = 100
        issues = []
        
        # Check for hardcoded API keys
        try:
            with open(f"{self.project_path}/lib/config/production_config.dart", 'r') as f:
                content = f.read()
                if 'dev-mapbox-token' in content or 'staging-mapbox-token' in content:
                    security_score -= 30
                    issues.append("Hardcoded API tokens found")
        except FileNotFoundError:
            pass
        
        # Check for missing input validation patterns
        try:
            with open(f"{self.project_path}/lib/voice/nlp/ride_intent_processor.dart", 'r') as f:
                content = f.read()
                if 'throw Exception' in content and 'input validation' not in content.lower():
                    security_score -= 20
                    issues.append("Missing input validation in voice processor")
        except FileNotFoundError:
            pass
        
        return {
            'score': max(0, security_score),
            'issues': issues,
            'status': 'secure' if security_score >= 80 else 'needs_attention'
        }
    
    def check_performance_metrics(self) -> Dict[str, Any]:
        """Check performance-related code patterns"""
        performance_score = 100
        issues = []
        
        # Check for potential memory leaks
        try:
            with open(f"{self.project_path}/lib/voice/core/voice_orchestrator.dart", 'r') as f:
                content = f.read()
                if 'Timer(' in content and 'dispose' not in content:
                    performance_score -= 15
                    issues.append("Potential Timer memory leak")
        except FileNotFoundError:
            pass
        
        # Check for expensive operations in UI thread
        try:
            with open(f"{self.project_path}/lib/services/firestore_service.dart", 'r') as f:
                content = f.read()
                if 'compute(' not in content and 'Isolate' not in content:
                    performance_score -= 10
                    issues.append("Heavy operations may block UI thread")
        except FileNotFoundError:
            pass
        
        return {
            'score': max(0, performance_score),
            'issues': issues,
            'status': 'good' if performance_score >= 80 else 'needs_optimization'
        }
    
    def check_code_quality(self) -> Dict[str, Any]:
        """Check code quality metrics"""
        quality_score = 100
        issues = []
        
        # Check for high complexity functions
        try:
            with open(f"{self.project_path}/lib/screens/active_ride_screen.dart", 'r') as f:
                content = f.read()
                if content.count('if ') > 50:  # Rough complexity indicator
                    quality_score -= 20
                    issues.append("High complexity detected in active_ride_screen")
        except FileNotFoundError:
            pass
        
        # Check for proper error handling
        try:
            with open(f"{self.project_path}/lib/services/firestore_service.dart", 'r') as f:
                content = f.read()
                if 'try {' in content and 'catch' not in content:
                    quality_score -= 15
                    issues.append("Missing error handling in firestore service")
        except FileNotFoundError:
            pass
        
        return {
            'score': max(0, quality_score),
            'issues': issues,
            'status': 'good' if quality_score >= 80 else 'needs_improvement'
        }
    
    def calculate_overall_score(self, metrics: Dict[str, Any]) -> int:
        """Calculate overall diagnostic score"""
        scores = [
            metrics.get('flutter_analyze', {}).get('score', 0),
            metrics.get('test_coverage', {}).get('score', 0),
            metrics.get('security', {}).get('score', 0),
            metrics.get('performance', {}).get('score', 0),
            metrics.get('code_quality', {}).get('score', 0)
        ]
        
        # Weight the scores (security and performance are more important)
        weights = [0.2, 0.15, 0.25, 0.25, 0.15]
        weighted_score = sum(score * weight for score, weight in zip(scores, weights))
        
        return int(weighted_score)
    
    def check_alerts(self, metrics: Dict[str, Any]) -> List[str]:
        """Check for alerts based on thresholds"""
        alerts = []
        
        overall_score = metrics.get('overall_score', 0)
        if overall_score < self.alert_thresholds['overall_score']:
            alerts.append(f"CRITICAL: Overall score {overall_score} below threshold {self.alert_thresholds['overall_score']}")
        
        security_score = metrics.get('security', {}).get('score', 0)
        if security_score < self.alert_thresholds['security_score']:
            alerts.append(f"HIGH: Security score {security_score} below threshold {self.alert_thresholds['security_score']}")
        
        test_coverage = metrics.get('test_coverage', {}).get('score', 0)
        if test_coverage < self.alert_thresholds['test_coverage']:
            alerts.append(f"MEDIUM: Test coverage {test_coverage}% below threshold {self.alert_thresholds['test_coverage']}%")
        
        return alerts
    
    def generate_report(self, metrics: Dict[str, Any]) -> str:
        """Generate human-readable report"""
        report = f"""
🔍 FRIENDSRIDE DIAGNOSTIC MONITORING REPORT
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

📊 OVERALL SCORE: {metrics.get('overall_score', 0)}/100

📋 COMPONENT SCORES:
• Flutter Analyze: {metrics.get('flutter_analyze', {}).get('score', 0)}/100
• Test Coverage: {metrics.get('test_coverage', {}).get('score', 0)}/100
• Security: {metrics.get('security', {}).get('score', 0)}/100
• Performance: {metrics.get('performance', {}).get('score', 0)}/100
• Code Quality: {metrics.get('code_quality', {}).get('score', 0)}/100

🚨 ALERTS:
"""
        
        alerts = self.check_alerts(metrics)
        if alerts:
            for alert in alerts:
                report += f"• {alert}\n"
        else:
            report += "• No alerts - all metrics within thresholds\n"
        
        report += f"""
📈 TREND ANALYSIS:
• Previous Score: {self.load_baseline().get('overall_score', 'N/A')}
• Change: {metrics.get('overall_score', 0) - self.load_baseline().get('overall_score', 0)}

🎯 RECOMMENDATIONS:
"""
        
        if metrics.get('overall_score', 0) < 80:
            report += "• Focus on improving security and code quality\n"
            report += "• Increase test coverage\n"
            report += "• Optimize performance bottlenecks\n"
        else:
            report += "• Maintain current quality standards\n"
            report += "• Continue monitoring for regressions\n"
        
        return report
    
    def run_diagnostic(self) -> Dict[str, Any]:
        """Run complete diagnostic analysis"""
        logging.info("Starting diagnostic analysis...")
        
        metrics = {
            'timestamp': datetime.now().isoformat(),
            'flutter_analyze': self.run_flutter_analyze(),
            'test_coverage': self.check_test_coverage(),
            'security': self.check_security_issues(),
            'performance': self.check_performance_metrics(),
            'code_quality': self.check_code_quality()
        }
        
        metrics['overall_score'] = self.calculate_overall_score(metrics)
        
        # Save metrics
        with open(self.metrics_file, 'w') as f:
            json.dump(metrics, f, indent=2)
        
        # Generate and log report
        report = self.generate_report(metrics)
        logging.info(report)
        
        # Check for alerts
        alerts = self.check_alerts(metrics)
        if alerts:
            logging.warning(f"ALERTS DETECTED: {len(alerts)} issues found")
            for alert in alerts:
                logging.warning(alert)
        
        return metrics
    
    def run_continuous_monitoring(self, interval_minutes: int = 60):
        """Run continuous monitoring with specified interval"""
        logging.info(f"Starting continuous monitoring with {interval_minutes} minute intervals...")
        
        while True:
            try:
                self.run_diagnostic()
                logging.info(f"Monitoring cycle completed. Next run in {interval_minutes} minutes.")
                time.sleep(interval_minutes * 60)
            except KeyboardInterrupt:
                logging.info("Monitoring stopped by user.")
                break
            except Exception as e:
                logging.error(f"Error in monitoring cycle: {e}")
                time.sleep(60)  # Wait 1 minute before retrying

def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='FriendsRide Diagnostic Monitor')
    parser.add_argument('--project-path', default='.', help='Path to Flutter project')
    parser.add_argument('--continuous', action='store_true', help='Run continuous monitoring')
    parser.add_argument('--interval', type=int, default=60, help='Monitoring interval in minutes')
    parser.add_argument('--baseline', action='store_true', help='Update baseline metrics')
    
    args = parser.parse_args()
    
    monitor = DiagnosticMonitor(args.project_path)
    
    if args.baseline:
        metrics = monitor.run_diagnostic()
        monitor.save_baseline(metrics)
        print("Baseline updated successfully.")
    elif args.continuous:
        monitor.run_continuous_monitoring(args.interval)
    else:
        metrics = monitor.run_diagnostic()
        print(monitor.generate_report(metrics))

if __name__ == "__main__":
    main()
