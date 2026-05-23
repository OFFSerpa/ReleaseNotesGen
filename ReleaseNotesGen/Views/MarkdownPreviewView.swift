//
//  MarkdownPreviewView.swift
//  ReleaseNotesGen
//
//  Created by Vinicius Pansan on 22/05/2026.
//

import SwiftUI
import WebKit

struct MarkdownPreviewView: NSViewRepresentable {
    let markdown: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(buildHTML(from: markdown), baseURL: nil)
    }

    // MARK: - HTML Builder

    private func buildHTML(from markdown: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                font-size: 13px;
                line-height: 1.6;
                color: #24292e;
                background: transparent;
                padding: 16px 20px;
                margin: 0;
            }
            h1 {
                font-size: 18px;
                font-weight: 700;
                border-bottom: 1px solid #e1e4e8;
                padding-bottom: 8px;
                margin: 0 0 16px 0;
            }
            h2 {
                font-size: 14px;
                font-weight: 600;
                margin: 20px 0 6px 0;
                color: #0969da;
            }
            ul { padding-left: 18px; margin: 4px 0 12px 0; }
            li { margin: 3px 0; }
            strong { font-weight: 600; }
            p { margin: 2px 0; color: #57606a; }
            @media (prefers-color-scheme: dark) {
                body { color: #e6edf3; }
                h1 { border-bottom-color: #30363d; }
                h2 { color: #58a6ff; }
                p { color: #8b949e; }
            }
        </style>
        </head>
        <body>\(markdownToHTML(markdown))</body>
        </html>
        """
    }

    // MARK: - Markdown to HTML

    private func markdownToHTML(_ markdown: String) -> String {
        var html = ""
        var inList = false

        for line in markdown.components(separatedBy: "\n") {
            if line.hasPrefix("# ") {
                if inList { html += "</ul>"; inList = false }
                html += "<h1>\(inline(String(line.dropFirst(2))))</h1>"
            } else if line.hasPrefix("## ") {
                if inList { html += "</ul>"; inList = false }
                html += "<h2>\(inline(String(line.dropFirst(3))))</h2>"
            } else if line.hasPrefix("- ") {
                if !inList { html += "<ul>"; inList = true }
                html += "<li>\(inline(String(line.dropFirst(2))))</li>"
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                if inList { html += "</ul>"; inList = false }
            } else {
                if inList { html += "</ul>"; inList = false }
                html += "<p>\(inline(line))</p>"
            }
        }

        if inList { html += "</ul>" }
        return html
    }

    private func inline(_ text: String) -> String {
        var s = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        if let regex = try? NSRegularExpression(pattern: #"\*\*(.+?)\*\*"#) {
            let range = NSRange(s.startIndex..., in: s)
            s = regex.stringByReplacingMatches(in: s, range: range, withTemplate: "<strong>$1</strong>")
        }
        return s
    }
}

#Preview {
    MarkdownPreviewView(markdown: "# Release Notes\n\n## Features\n\n- feat: add preview (abc1234)")
        .frame(width: 400, height: 300)
}
