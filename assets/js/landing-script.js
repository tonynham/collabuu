// Landing Page JavaScript
console.log('Landing script loaded successfully!');

document.addEventListener('DOMContentLoaded', function() {
    console.log('DOM loaded, initializing landing script...');
    
    // Initialize lazy loading for images
    initializeLazyLoading();
    
    // Mobile-specific optimizations
    initializeMobileOptimizations();
    
    // Initialize mobile carousels
    initializeMobileCarousels();
    
    // Navbar scroll effect
    const navbar = document.getElementById('navbar');
    const heroSection = document.querySelector('.hero-landing');
    const audienceSelectorSection = document.querySelector('.audience-selector-section');
    
    console.log('Found elements:', {
        navbar: !!navbar,
        heroSection: !!heroSection,
        audienceSelectorSection: !!audienceSelectorSection
    });
    
    // Get navigation elements
    const navDynamicItems = document.querySelectorAll('.nav-item-dynamic');
    const navAppStore = document.getElementById('nav-app-store');
    
    // Mobile menu functionality
    const mobileMenuToggle = document.getElementById('mobileMenuToggle');
    const navMenu = document.getElementById('navMenu');
    let isMobileMenuOpen = false;

    if (mobileMenuToggle && navMenu) {
        mobileMenuToggle.addEventListener('click', () => {
            isMobileMenuOpen = !isMobileMenuOpen;
            
            if (isMobileMenuOpen) {
                navMenu.classList.add('mobile-menu-open');
                mobileMenuToggle.classList.add('active');
                document.body.style.overflow = 'hidden'; // Prevent background scrolling
            } else {
                navMenu.classList.remove('mobile-menu-open');
                mobileMenuToggle.classList.remove('active');
                document.body.style.overflow = '';
            }
        });

        // Close mobile menu when clicking on nav links
        const navLinks = navMenu.querySelectorAll('.nav-link');
        navLinks.forEach(link => {
            link.addEventListener('click', () => {
                navMenu.classList.remove('mobile-menu-open');
                mobileMenuToggle.classList.remove('active');
                document.body.style.overflow = '';
                isMobileMenuOpen = false;
            });
        });

        // Close mobile menu when clicking outside
        document.addEventListener('click', (e) => {
            if (isMobileMenuOpen && !navMenu.contains(e.target) && !mobileMenuToggle.contains(e.target)) {
                navMenu.classList.remove('mobile-menu-open');
                mobileMenuToggle.classList.remove('active');
                document.body.style.overflow = '';
                isMobileMenuOpen = false;
            }
        });

        // Close mobile menu on escape key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && isMobileMenuOpen) {
                navMenu.classList.remove('mobile-menu-open');
                mobileMenuToggle.classList.remove('active');
                document.body.style.overflow = '';
                isMobileMenuOpen = false;
            }
        });
    }
    
    // Track if user has made a selection
    let hasSelectedAudience = false;
    
    window.addEventListener('scroll', () => {
        const scrollY = window.scrollY;
        const heroHeight = heroSection.offsetHeight;
        const audienceSelectorTop = audienceSelectorSection.offsetTop;
        
        // Handle navbar light/dark mode
        if (scrollY > 100) {
            navbar.classList.add('light-mode');
            document.body.classList.add('scrolled-past-hero');
        } else {
            navbar.classList.remove('light-mode');
            document.body.classList.remove('scrolled-past-hero');
        }
        
        // Handle navigation items visibility based on scroll position
        if (hasSelectedAudience) {
            // If user is in hero section (before audience selector), hide nav items
            if (scrollY < audienceSelectorTop - 100) {
                hideNavigationItems();
            } else {
                // If user is at or past audience selector, show nav items
                showNavigationItems();
            }
        }
    });

    function showNavigationItems() {
        navDynamicItems.forEach(item => {
            item.classList.remove('nav-item-hidden');
            item.classList.add('nav-item-visible');
        });
        if (navAppStore) {
            navAppStore.classList.remove('nav-item-hidden');
            navAppStore.classList.add('nav-item-visible');
        }
    }

    function hideNavigationItems() {
        navDynamicItems.forEach(item => {
            item.classList.remove('nav-item-visible');
            item.classList.add('nav-item-hidden');
        });
        if (navAppStore) {
            navAppStore.classList.remove('nav-item-visible');
            navAppStore.classList.add('nav-item-hidden');
        }
    }

    // Main Audience Selection Functionality
    const mainTabButtons = document.querySelectorAll('.main-tab-btn');
    const audienceExperiences = document.querySelectorAll('.audience-experience');
    const dynamicContent = document.getElementById('dynamic-content');
    
    console.log('Audience selection elements:', {
        mainTabButtons: mainTabButtons.length,
        audienceExperiences: audienceExperiences.length,
        dynamicContent: !!dynamicContent,
        dynamicContentHidden: dynamicContent?.classList.contains('hidden')
    });
    
    if (mainTabButtons.length === 0) {
        console.error('No main tab buttons found! Check if .main-tab-btn elements exist');
    }
    
    mainTabButtons.forEach((button, index) => {
        console.log(`Setting up button ${index}:`, button.getAttribute('data-audience'));
        button.addEventListener('click', (e) => {
            console.log('=== BUTTON CLICKED ===');
            e.preventDefault();
            const targetAudience = button.getAttribute('data-audience');
            console.log('Audience selected:', targetAudience);
            
            // Remove active class from all main tabs
            mainTabButtons.forEach(btn => btn.classList.remove('active'));
            
            // Remove active class from all experiences
            audienceExperiences.forEach(experience => experience.classList.remove('active'));
            
            // Add active class to clicked button and corresponding experience
            button.classList.add('active');
            const targetExperience = document.getElementById(`${targetAudience}-experience`);
            console.log('Target experience element:', targetExperience);
            if (targetExperience) {
                targetExperience.classList.add('active');
                console.log('Added active class to experience');
            }
            
            // Show dynamic content area if it's hidden
            if (dynamicContent && dynamicContent.classList.contains('hidden')) {
                dynamicContent.classList.remove('hidden');
                console.log('Removed hidden class from dynamic content');
            }
            
            // Mark that user has selected an audience and show navigation
            hasSelectedAudience = true;
            showNavigationItems();
            
            // Show mobile menu toggle after audience selection
            if (mobileMenuToggle) {
                mobileMenuToggle.classList.add('show-after-selection');
            }
            
            // Smooth scroll to the first section of their experience (immediate, like "Choose Your Path")
            const firstSection = targetExperience?.querySelector('.features-section');
            if (firstSection) {
                console.log('Scrolling to first section');
                firstSection.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Legacy tab functionality for individual sections (if they exist)
    const tabButtons = document.querySelectorAll('.tab-btn');
    
    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            const targetAudience = button.getAttribute('data-audience');
            const section = button.getAttribute('data-section') || 'features';
            
            // Get all tabs and panels for this specific section
            const sectionPanels = section === 'how-it-works' 
                ? document.querySelectorAll('[id^="how-it-works-"][id$="-panel"]')
                : document.querySelectorAll('[id$="-panel"]:not([id*="how-it-works"])');
            
            // Remove active class from tabs in this section only
            if (section === 'how-it-works') {
                document.querySelectorAll('.how-it-works-tabs .tab-btn').forEach(btn => btn.classList.remove('active'));
            } else {
                document.querySelectorAll('.audience-tabs:not(.how-it-works-tabs) .tab-btn').forEach(btn => btn.classList.remove('active'));
            }
            
            // Remove active class from panels in this section only
            sectionPanels.forEach(panel => panel.classList.remove('active'));
            
            // Add active class to clicked button and corresponding panel
            button.classList.add('active');
            const panelId = section === 'how-it-works' 
                ? `how-it-works-${targetAudience}-panel`
                : `${targetAudience}-panel`;
            const targetPanel = document.getElementById(panelId);
            if (targetPanel) {
                targetPanel.classList.add('active');
            }
        });
    });

    // Smooth scrolling for navigation links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const targetId = this.getAttribute('href').substring(1);
            let target = null;
            
            // Handle special navigation for features and how-it-works
            if (targetId === 'features' || targetId === 'how-it-works') {
                // Find the active audience experience
                const activeExperience = document.querySelector('.audience-experience.active');
                if (activeExperience) {
                    // Look for the section within the active experience
                    target = activeExperience.querySelector(`#${targetId}, .${targetId}-section`);
                }
                // Fallback to the first section if not found
                if (!target) {
                    target = document.querySelector(`#${targetId}, .${targetId}-section`);
                }
            } else {
                target = document.querySelector(`#${targetId}`);
            }
            
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Add animation on scroll for feature cards and step cards
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    // Observe all feature cards and step cards
    document.querySelectorAll('.feature-card, .step-card').forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(30px)';
        card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(card);
    });
});

// Lazy Loading Implementation
function initializeLazyLoading() {
    // Use Intersection Observer for lazy loading if supported
    if ('IntersectionObserver' in window) {
        const imageObserver = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const img = entry.target;
                    img.src = img.src; // Trigger actual loading
                    img.classList.add('loaded');
                    observer.unobserve(img);
                }
            });
        }, {
            rootMargin: '50px 0px',
            threshold: 0.01
        });

        // Observe all lazy images
        document.querySelectorAll('img[loading="lazy"]').forEach(img => {
            imageObserver.observe(img);
        });
    }
}

// Mobile-specific optimizations
function initializeMobileOptimizations() {
    // Prevent zoom on input focus for iOS
    if (/iPad|iPhone|iPod/.test(navigator.userAgent)) {
        const viewportMeta = document.querySelector('meta[name="viewport"]');
        if (viewportMeta) {
            const originalContent = viewportMeta.content;
            
            // Add event listeners to prevent zoom on focus
            document.addEventListener('focusin', () => {
                viewportMeta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            });
            
            document.addEventListener('focusout', () => {
                viewportMeta.content = originalContent;
            });
        }
    }
    
    // Optimize touch events for better performance
    document.addEventListener('touchstart', function() {}, { passive: true });
    document.addEventListener('touchmove', function() {}, { passive: true });
    
    // Add mobile-specific class for styling
    if (window.innerWidth <= 768) {
        document.body.classList.add('mobile-device');
    }
    
    // Handle orientation changes
    window.addEventListener('orientationchange', () => {
        // Delay to ensure proper rendering after orientation change
        setTimeout(() => {
            window.scrollTo(0, 0);
            // Recalculate any dynamic heights if needed
            const heroSection = document.querySelector('.hero-landing');
            if (heroSection) {
                heroSection.style.minHeight = window.innerHeight + 'px';
            }
        }, 100);
    });
    
    // Improve scrolling performance on mobile
    let ticking = false;
    
    function updateOnScroll() {
        // Throttle scroll events for better performance
        if (!ticking) {
            requestAnimationFrame(() => {
                // Add any scroll-based animations here
                ticking = false;
            });
            ticking = true;
        }
    }
    
    window.addEventListener('scroll', updateOnScroll, { passive: true });
    
    // Preload critical images for better mobile experience
    const criticalImages = [
        'assets/images/business-icon.png',
        'assets/images/influencer-icon.png',
        'assets/images/customer-icon.png'
    ];
    
    criticalImages.forEach(src => {
        const img = new Image();
        img.src = src;
    });
}

// Mobile Carousel Implementation
function initializeMobileCarousels() {
    console.log('Initializing mobile carousels...');
    
    // Only initialize on mobile devices
    if (window.innerWidth <= 768) {
        initializeCarousel('.features-grid', '.feature-card');
        initializeCarousel('.steps-container', '.step-card');
        initializeCarousel('.pricing-grid', '.pricing-card');
    }
    
    // Re-initialize on window resize
    window.addEventListener('resize', () => {
        if (window.innerWidth <= 768) {
            initializeCarousel('.features-grid', '.feature-card');
            initializeCarousel('.steps-container', '.step-card');
            initializeCarousel('.pricing-grid', '.pricing-card');
        }
    });
}

function initializeCarousel(containerSelector, itemSelector) {
    const containers = document.querySelectorAll(containerSelector);
    
    containers.forEach((container, containerIndex) => {
        const items = container.querySelectorAll(itemSelector);
        if (items.length <= 1) return; // No need for carousel with 1 or fewer items
        
        // Add carousel hint class
        container.parentElement.classList.add('carousel-hint');
        
        // Create and add indicators
        const indicatorsContainer = createCarouselIndicators(items.length, `${containerSelector.replace('.', '')}-${containerIndex}`);
        container.parentElement.appendChild(indicatorsContainer);
        
        // Set up scroll event listener for indicator updates
        let scrollTimeout;
        container.addEventListener('scroll', () => {
            clearTimeout(scrollTimeout);
            scrollTimeout = setTimeout(() => {
                updateCarouselIndicators(container, items, indicatorsContainer);
            }, 100);
        });
        
        // Set up indicator click handlers
        const indicators = indicatorsContainer.querySelectorAll('.carousel-dot');
        indicators.forEach((indicator, index) => {
            indicator.addEventListener('click', () => {
                scrollToItem(container, items[index]);
            });
        });
        
        // Enhanced touch/swipe handling
        let startX = 0;
        let scrollLeft = 0;
        let isDown = false;
        let hasMoved = false;
        
        container.addEventListener('touchstart', (e) => {
            startX = e.touches[0].pageX - container.offsetLeft;
            scrollLeft = container.scrollLeft;
            isDown = true;
            hasMoved = false;
            container.style.scrollBehavior = 'auto';
        }, { passive: true });
        
        container.addEventListener('touchmove', (e) => {
            if (!isDown) return;
            hasMoved = true;
            const x = e.touches[0].pageX - container.offsetLeft;
            const walk = (x - startX) * 2;
            container.scrollLeft = scrollLeft - walk;
        }, { passive: true });
        
        container.addEventListener('touchend', () => {
            isDown = false;
            container.style.scrollBehavior = 'smooth';
            
            // Snap to nearest item if user swiped significantly
            if (hasMoved) {
                snapToNearestItem(container, items);
            }
        });
        
        // Mouse support for desktop testing
        container.addEventListener('mousedown', (e) => {
            startX = e.pageX - container.offsetLeft;
            scrollLeft = container.scrollLeft;
            isDown = true;
            hasMoved = false;
            container.style.cursor = 'grabbing';
            container.style.scrollBehavior = 'auto';
        });
        
        container.addEventListener('mousemove', (e) => {
            if (!isDown) return;
            e.preventDefault();
            hasMoved = true;
            const x = e.pageX - container.offsetLeft;
            const walk = (x - startX) * 2;
            container.scrollLeft = scrollLeft - walk;
        });
        
        container.addEventListener('mouseup', () => {
            isDown = false;
            container.style.cursor = 'grab';
            container.style.scrollBehavior = 'smooth';
            
            if (hasMoved) {
                snapToNearestItem(container, items);
            }
        });
        
        container.addEventListener('mouseleave', () => {
            isDown = false;
            container.style.cursor = 'grab';
            container.style.scrollBehavior = 'smooth';
        });
        
        // Initial indicator update
        updateCarouselIndicators(container, items, indicatorsContainer);
    });
}

function createCarouselIndicators(count, id) {
    const indicatorsContainer = document.createElement('div');
    indicatorsContainer.className = 'carousel-indicators';
    indicatorsContainer.id = `indicators-${id}`;
    
    for (let i = 0; i < count; i++) {
        const dot = document.createElement('div');
        dot.className = 'carousel-dot';
        if (i === 0) dot.classList.add('active');
        indicatorsContainer.appendChild(dot);
    }
    
    return indicatorsContainer;
}

function updateCarouselIndicators(container, items, indicatorsContainer) {
    const containerWidth = container.offsetWidth;
    const scrollLeft = container.scrollLeft;
    const itemWidth = items[0].offsetWidth + 20; // Including gap
    
    // Calculate which item is most visible
    const activeIndex = Math.round(scrollLeft / itemWidth);
    const clampedIndex = Math.max(0, Math.min(activeIndex, items.length - 1));
    
    // Update indicators
    const indicators = indicatorsContainer.querySelectorAll('.carousel-dot');
    indicators.forEach((indicator, index) => {
        indicator.classList.toggle('active', index === clampedIndex);
    });
}

function scrollToItem(container, item) {
    const containerRect = container.getBoundingClientRect();
    const itemRect = item.getBoundingClientRect();
    const scrollLeft = item.offsetLeft - container.offsetLeft - (containerRect.width - itemRect.width) / 2;
    
    container.scrollTo({
        left: Math.max(0, scrollLeft),
        behavior: 'smooth'
    });
}

function snapToNearestItem(container, items) {
    const containerWidth = container.offsetWidth;
    const scrollLeft = container.scrollLeft;
    const itemWidth = items[0].offsetWidth + 20; // Including gap
    
    const targetIndex = Math.round(scrollLeft / itemWidth);
    const clampedIndex = Math.max(0, Math.min(targetIndex, items.length - 1));
    
    scrollToItem(container, items[clampedIndex]);
} 