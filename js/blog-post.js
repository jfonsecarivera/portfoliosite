/**
 * Unified Blog Post JavaScript
 * Common functionality for blog posts on joshfonseca.com
 */

(function() {
    'use strict';

    // --- READING PROGRESS BAR ---
    function initProgressBar() {
        const progressBar = document.getElementById('progressBar');
        if (!progressBar) return;

        window.addEventListener('scroll', () => {
            const winScroll = document.body.scrollTop || document.documentElement.scrollTop;
            const height = document.documentElement.scrollHeight - document.documentElement.clientHeight;
            const scrolled = (winScroll / height) * 100;
            progressBar.style.width = scrolled + '%';
        });
    }

    // --- TOC VISIBILITY & ACTIVE SECTION TRACKING ---
    function initTOC() {
        const tocSidebar = document.querySelector('.toc-sidebar');
        if (!tocSidebar) return;

        const heroSection = document.getElementById('intro') || document.querySelector('.hero-section');
        const footerSection = document.querySelector('footer');
        const sections = document.querySelectorAll('section[id], header[id]');
        const tocLinks = document.querySelectorAll('.toc-link');

        function updateTOCVisibility() {
            if (!heroSection || !footerSection) return;

            const heroBottom = heroSection.offsetTop + heroSection.offsetHeight;
            const footerTop = footerSection.offsetTop;
            const scrollY = window.scrollY || window.pageYOffset;
            const windowHeight = window.innerHeight;

            if (scrollY > heroBottom - 100 && scrollY + windowHeight < footerTop + 200) {
                tocSidebar.classList.add('visible');
            } else {
                tocSidebar.classList.remove('visible');
            }
        }

        function updateActiveSection() {
            const scrollY = window.scrollY || window.pageYOffset;
            let currentSection = '';

            sections.forEach(section => {
                const sectionTop = section.offsetTop;
                const sectionHeight = section.offsetHeight;

                if (scrollY >= sectionTop - 200 && scrollY < sectionTop + sectionHeight) {
                    currentSection = section.id;
                }
            });

            tocLinks.forEach(link => {
                link.classList.remove('active');
                if (link.getAttribute('href') === `#${currentSection}`) {
                    link.classList.add('active');
                }
            });
        }

        let ticking = false;
        function onScroll() {
            if (!ticking) {
                window.requestAnimationFrame(() => {
                    updateTOCVisibility();
                    updateActiveSection();
                    ticking = false;
                });
                ticking = true;
            }
        }

        window.addEventListener('scroll', onScroll);
        updateTOCVisibility();
        updateActiveSection();
    }

    // --- TYPING EFFECT ---
    function typeWriter(element, text, speed = 30) {
        element.innerHTML = '';
        element.classList.add('typing-cursor');

        let i = 0;

        function type() {
            if (i < text.length) {
                element.innerHTML += text.charAt(i);
                i++;
                setTimeout(type, speed + (Math.random() * 20));
            } else {
                element.classList.remove('typing-cursor');
            }
        }
        type();
    }

    // --- SCROLL REVEAL ---
    function initScrollReveal() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('active');

                    const typeElements = entry.target.querySelectorAll('.type-text');
                    typeElements.forEach(el => {
                        if (!el.dataset.typed) {
                            el.dataset.typed = 'true';
                            const text = el.innerText;
                            if (el.children.length > 0) {
                                el.style.opacity = 0;
                                setTimeout(() => {
                                    el.style.transition = 'opacity 1s';
                                    el.style.opacity = 1;
                                }, 200);
                            } else {
                                typeWriter(el, text);
                            }
                        }
                    });
                }
            });
        }, { threshold: 0.1 });

        document.querySelectorAll('.reveal').forEach(el => observer.observe(el));
    }

    // --- COPY TO CLIPBOARD ---
    window.copyCode = function(btn) {
        const pre = btn.nextElementSibling;
        const code = pre.querySelector('code') || pre;
        const text = code.innerText;

        navigator.clipboard.writeText(text).then(() => {
            const originalText = btn.innerText;
            btn.innerText = 'Copied!';
            btn.style.borderColor = 'var(--accent-green)';
            btn.style.color = 'var(--accent-green)';

            setTimeout(() => {
                btn.innerText = originalText;
                btn.style.borderColor = 'rgba(255, 255, 255, 0.2)';
                btn.style.color = '#ccc';
            }, 2000);
        });
    };

    // --- INITIALIZE ON DOM READY ---
    function init() {
        initProgressBar();
        initTOC();
        initScrollReveal();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
