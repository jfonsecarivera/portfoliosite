document.addEventListener("DOMContentLoaded", function() {
    // Add RSS feed autodiscovery link
    if (!document.querySelector('link[type="application/rss+xml"]')) {
        const rssLink = document.createElement('link');
        rssLink.rel = 'alternate';
        rssLink.type = 'application/rss+xml';
        rssLink.title = "Josh Fonseca's Blog";
        rssLink.href = '/feed.xml';
        document.head.appendChild(rssLink);
    }

    // Helper function to load HTML into an element
    function loadTemplate(elementId, url) {
        const element = document.getElementById(elementId);
        if (!element) return;

        fetch(url)
            .then(response => {
                if (!response.ok) throw new Error(`Failed to load ${url}`);
                return response.text();
            })
            .then(html => {
                element.innerHTML = html;
            })
            .catch(error => console.error('Error loading template:', error));
    }

    loadTemplate("header", "/templates/header.html");
    loadTemplate("footer", "/templates/footer.html");

    // Initialize copy buttons for code blocks
    initCopyButtons();
});

function initCopyButtons() {
    // Inject CSS styles for copy buttons
    if (!document.getElementById('copy-btn-styles')) {
        const style = document.createElement('style');
        style.id = 'copy-btn-styles';
        style.textContent = `
            .code-container {
                position: relative;
                margin: 1.5rem 0;
            }
            .copy-btn {
                position: absolute;
                top: 10px;
                right: 10px;
                background: rgba(255, 255, 255, 0.1);
                border: 1px solid rgba(255, 255, 255, 0.2);
                color: #ccc;
                padding: 5px 10px;
                border-radius: 4px;
                font-size: 0.75rem;
                cursor: pointer;
                transition: all 0.2s;
                font-family: 'Inter', sans-serif;
                text-transform: uppercase;
                letter-spacing: 0.05em;
                z-index: 5;
            }
            .copy-btn:hover {
                background: rgba(255, 255, 255, 0.2);
                color: #fff;
                border-color: #fff;
            }
        `;
        document.head.appendChild(style);
    }

    // Find all pre elements with code children that aren't already wrapped
    document.querySelectorAll('pre > code').forEach(code => {
        const pre = code.parentElement;

        // Skip if already wrapped in a code-container
        if (pre.parentElement.classList.contains('code-container')) {
            return;
        }

        // Create wrapper
        const container = document.createElement('div');
        container.className = 'code-container';

        // Create copy button
        const btn = document.createElement('button');
        btn.className = 'copy-btn';
        btn.textContent = 'Copy';
        btn.addEventListener('click', () => copyCode(btn, code));

        // Wrap the pre element
        pre.parentNode.insertBefore(container, pre);
        container.appendChild(btn);
        container.appendChild(pre);
    });
}

function copyCode(btn, code) {
    const text = code.innerText;

    navigator.clipboard.writeText(text).then(() => {
        const originalText = btn.textContent;
        btn.textContent = 'Copied!';
        btn.style.borderColor = '#10b981';
        btn.style.color = '#10b981';

        setTimeout(() => {
            btn.textContent = originalText;
            btn.style.borderColor = 'rgba(255, 255, 255, 0.2)';
            btn.style.color = '#ccc';
        }, 2000);
    }).catch(err => {
        console.error('Failed to copy:', err);
    });
}
