/* ============================================================
   BURNOUT RADAR — Vanilla JS
   Replicates all React/Framer Motion interactions
   ============================================================ */

document.addEventListener('DOMContentLoaded', () => {

    /* ─────────────────────────────────────────────
       1. NAVBAR — scroll glass + mobile menu
    ───────────────────────────────────────────── */
    const navbar = document.getElementById('navbar');
    const hamburger = document.getElementById('hamburger');
    const mobileMenu = document.getElementById('mobile-menu');

    window.addEventListener('scroll', () => {
        navbar.classList.toggle('scrolled', window.scrollY > 20);
    }, { passive: true });

    hamburger.addEventListener('click', () => {
        mobileMenu.classList.toggle('open');
        hamburger.textContent = mobileMenu.classList.contains('open') ? '✕' : '☰';
    });

    // close mobile menu when a link is clicked
    mobileMenu.querySelectorAll('a').forEach(a => {
        a.addEventListener('click', () => {
            mobileMenu.classList.remove('open');
            hamburger.textContent = '☰';
        });
    });

    /* ─────────────────────────────────────────────
       2. NAVBAR entrance animation
    ───────────────────────────────────────────── */
    navbar.style.transform = 'translateY(-80px)';
    navbar.style.opacity = '0';
    navbar.style.transition = 'transform 0.6s ease, opacity 0.6s ease, background 0.3s, box-shadow 0.3s';
    requestAnimationFrame(() => {
        setTimeout(() => {
            navbar.style.transform = 'translateY(0)';
            navbar.style.opacity = '1';
        }, 50);
    });

    /* ─────────────────────────────────────────────
       3. HERO entrance stagger
    ───────────────────────────────────────────── */
    const heroItems = [
        { el: document.getElementById('hero-badge'), delay: 300, from: 'scale' },
        { el: document.getElementById('hero-title'), delay: 500, from: 'bottom' },
        { el: document.getElementById('hero-desc'), delay: 700, from: 'bottom' },
        { el: document.getElementById('hero-cta'), delay: 900, from: 'bottom' },
        { el: document.getElementById('hero-img-col'), delay: 400, from: 'right' },
    ];
    heroItems.forEach(({ el, delay, from }) => {
        if (!el) return;
        el.style.opacity = '0';
        el.style.transition = `opacity 0.7s ${delay}ms ease, transform 0.7s ${delay}ms ease`;
        if (from === 'scale') el.style.transform = 'scale(0.5) translateY(20px)';
        if (from === 'bottom') el.style.transform = 'translateY(30px)';
        if (from === 'right') el.style.transform = 'translateX(60px)';
        requestAnimationFrame(() => {
            setTimeout(() => {
                el.style.opacity = '1';
                el.style.transform = 'translate(0) scale(1)';
            }, delay);
        });
    });

    /* ─────────────────────────────────────────────
       4. INTERSECTION OBSERVER — generic .reveal
    ───────────────────────────────────────────── */
    const revealObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            entry.target.classList.toggle('visible', entry.isIntersecting);
        });
    }, { threshold: 0.15 });

    document.querySelectorAll('.reveal').forEach(el => revealObserver.observe(el));

    /* ─────────────────────────────────────────────
       5. PROBLEM CARDS — slide in from sides (re-hide on exit)
    ───────────────────────────────────────────── */
    const problemObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            const el = entry.target;
            el.classList.toggle('visible', entry.isIntersecting);
        });
    }, { threshold: 0.2, rootMargin: '-80px' });

    document.querySelectorAll('.problem-text-card, .problem-img-col').forEach(el => {
        problemObserver.observe(el);
    });

    /* ─────────────────────────────────────────────
       6. DESCRIPTION section
    ───────────────────────────────────────────── */
    const descObserver = new IntersectionObserver((entries) => {
        entries.forEach(e => e.target.classList.toggle('visible', e.isIntersecting));
    }, { threshold: 0.15 });
    document.querySelectorAll('.desc-visual, .desc-content').forEach(el => descObserver.observe(el));

    /* ─────────────────────────────────────────────
       7. WORKFLOW — staggered beat animations
    ───────────────────────────────────────────── */
    const wfObserver = new IntersectionObserver((entries) => {
        entries.forEach(e => {
            e.target.classList.toggle('visible', e.isIntersecting);
        });
    }, { threshold: 0.15, rootMargin: '-80px' });

    document.querySelectorAll('.wf-images, .wf-card, .workflow-dot').forEach(el => wfObserver.observe(el));

    /* ─────────────────────────────────────────────
       8. FEATURES — fade up + 3D tilt on hover
    ───────────────────────────────────────────── */
    const featureObserver = new IntersectionObserver((entries) => {
        entries.forEach(e => e.target.classList.toggle('visible', e.isIntersecting));
    }, { threshold: 0.15 });

    document.querySelectorAll('.feature-card').forEach((card, i) => {
        card.style.transitionDelay = `${i * 0.1}s`;
        featureObserver.observe(card);

        // 3D tilt
        card.addEventListener('mousemove', (e) => {
            const rect = card.getBoundingClientRect();
            const cx = rect.left + rect.width / 2;
            const cy = rect.top + rect.height / 2;
            const dx = (e.clientX - cx) / (rect.width / 2);
            const dy = (e.clientY - cy) / (rect.height / 2);
            const rx = dy * -8;
            const ry = dx * 8;
            card.style.transform = `perspective(600px) rotateX(${rx}deg) rotateY(${ry}deg) scale(1.04) translateY(0)`;
        });
        card.addEventListener('mouseleave', () => {
            card.style.transform = card.classList.contains('visible')
                ? 'perspective(600px) rotateX(0deg) rotateY(0deg) scale(1) translateY(0)'
                : 'perspective(600px) rotateX(0deg) rotateY(0deg) scale(1) translateY(40px)';
        });

        // float animation with stagger
        card.style.animationDelay = `${i * 0.8}s`;
        card.classList.add('animate-float-card');
    });

    /* ─────────────────────────────────────────────
       9. APP EXPERIENCE — scroll-locked horizontal navigation
    ───────────────────────────────────────────── */
    const expSection = document.getElementById('experience');
    const expHeader = expSection ? expSection.querySelector('.exp-header') : null;
    const expHint = expSection ? expSection.querySelector('.exp-hint') : null;
    const expScrollHint = expSection ? expSection.querySelector('.exp-scroll-hint') : null;
    const expDots = expSection ? expSection.querySelectorAll('.exp-dot') : [];
    const expScreenImgs = expSection ? expSection.querySelectorAll('.exp-screen-img') : [];
    const expPrevArrow = expSection ? expSection.querySelector('.exp-nav-arrow.prev') : null;
    const expNextArrow = expSection ? expSection.querySelector('.exp-nav-arrow.next') : null;
    const expPrevLabel = expPrevArrow ? expPrevArrow.querySelector('.exp-arrow-label') : null;
    const expNextLabel = expNextArrow ? expNextArrow.querySelector('.exp-arrow-label') : null;

    const APP_SCREENS = [
        { name: 'Mood Logging', emoji: '\uD83D\uDCCB' },
        { name: 'Breathing Exercise', emoji: '\uD83C\uDF2C\uFE0F' },
        { name: 'Meditation', emoji: '\uD83E\uDDD8' },
        { name: 'Exercise Tasks', emoji: '\uD83C\uDFC3' },
        { name: 'Progress Analysis', emoji: '\uD83D\uDCCA' },
        { name: 'Achievement Screen', emoji: '\uD83C\uDFC6' },
    ];

    let currentScreen = 0;
    let expDone = false;
    let expCooldown = false;
    expHeader?.classList.add('visible');

    function setScreen(idx) {
  const old = expScreenImgs[currentScreen];
  const next = expScreenImgs[idx];
  if (!old || !next) return;

  old.classList.remove('active');
  next.classList.add('active');

  currentScreen = idx;

  // dots
  expDots.forEach((d, i) => d.classList.toggle('active', i === idx));

  // arrows
  expPrevArrow?.classList.toggle('visible', idx > 0);
  expNextArrow?.classList.toggle('visible', idx < expScreenImgs.length - 1);
}

    // initialise first screen
    if (expScreenImgs.length) {
        expScreenImgs[0].classList.add('active');
        if (expPrevArrow) expPrevArrow.classList.remove('visible');
        if (expNextArrow) {
            expNextArrow.classList.add('visible');
            if (expNextLabel) expNextLabel.textContent = APP_SCREENS[1].name;
        }
    }


    function handleExpScroll(delta) {
        if (expDone) return;


        if (expCooldown) return true;
        expCooldown = true;
        setTimeout(() => { expCooldown = false; }, 600);

        if (delta > 0) {
            const next = currentScreen + 1;
            if (next < APP_SCREENS.length) {
                setScreen(next, 1);
            } else {
                // reached end — unlock vertical scroll
                expDone = true;

                if (expScrollHint) expScrollHint.style.display = 'none';
                if (expHint) expHint.textContent = 'All screens explored!';
            }
        } else {
            const prev = currentScreen - 1;
            if (prev >= 0) setScreen(prev, -1);
        }
        return true; // consumed
    }


    let touchStartX = 0;
    let touchEndX = 0;

    const SWIPE_THRESHOLD = 50; // sensitivity

    // start touch
    expSection.addEventListener('touchstart', (e) => {
        touchStartX = e.touches[0].clientX;
    }, { passive: true });

    // end touch
    expSection.addEventListener('touchend', (e) => {
        touchEndX = e.changedTouches[0].clientX;
        handleSwipe();
    }, { passive: true });

    function handleSwipe() {
        const deltaX = touchStartX - touchEndX;

        // ignore small swipes
        if (Math.abs(deltaX) < SWIPE_THRESHOLD) return;

        if (deltaX > 0) {
            // swipe left → next screen
            if (currentScreen < expScreenImgs.length - 1) {
                setScreen(currentScreen + 1, 1);
            }
        } else {
            // swipe right → previous screen
            if (currentScreen > 0) {
                setScreen(currentScreen - 1, -1);
            }
        }
    }

    let touchStartY = 0;

    expSection.addEventListener('touchstart', (e) => {
        touchStartX = e.touches[0].clientX;
        touchStartY = e.touches[0].clientY;
    }, { passive: true });

    function handleSwipe() {
        const deltaX = touchStartX - touchEndX;
        const deltaY = touchStartY - (event?.changedTouches?.[0]?.clientY || 0);

        // only trigger if horizontal swipe is stronger than vertical
        if (Math.abs(deltaX) < Math.abs(deltaY)) return;

        if (Math.abs(deltaX) < SWIPE_THRESHOLD) return;

        if (deltaX > 0) {
            if (currentScreen < expScreenImgs.length - 1) {
                setScreen(currentScreen + 1, 1);
            }
        } else {
            if (currentScreen > 0) {
                setScreen(currentScreen - 1, -1);
            }
        }
    }

    // dot clicks
    expDots.forEach((dot, i) => {
        dot.addEventListener('click', () => setScreen(i, i > currentScreen ? 1 : -1));
    });

    let lastScrollY = window.scrollY;

    expNextArrow?.addEventListener('click', () => {
        if (currentScreen < expScreenImgs.length - 1) {
            setScreen(currentScreen + 1, 1);
        }
    });

    expPrevArrow?.addEventListener('click', () => {
        if (currentScreen > 0) {
            setScreen(currentScreen - 1, -1);
        }
    });
    /* ─────────────────────────────────────────────
       10. TRANSFORMATION section observers
    ───────────────────────────────────────────── */
    const transObserver = new IntersectionObserver((entries) => {
        entries.forEach(e => e.target.classList.toggle('visible', e.isIntersecting));
    }, { threshold: 0.15 });
    document.querySelectorAll('.transform-before, .transform-after').forEach(el => transObserver.observe(el));

    const activityObserver = new IntersectionObserver((entries) => {
        entries.forEach(e => e.target.classList.toggle('visible', e.isIntersecting));
    }, { threshold: 0.1 });
    document.querySelectorAll('.activity-card').forEach((el, i) => {
        el.style.transitionDelay = `${i * 0.1}s`;
        activityObserver.observe(el);
    });

    /* ─────────────────────────────────────────────
       11. BENEFITS & TEAM observers
    ───────────────────────────────────────────── */
    const cardObserver = new IntersectionObserver((entries) => {
        entries.forEach(e => e.target.classList.toggle('visible', e.isIntersecting));
    }, { threshold: 0.1 });
    document.querySelectorAll('.benefit-card, .team-card').forEach((el, i) => {
        el.style.transitionDelay = `${i * 0.1}s`;
        cardObserver.observe(el);
    });

    /* ─────────────────────────────────────────────
       12. CTA scale-in
    ───────────────────────────────────────────── */
    const ctaObserver = new IntersectionObserver(([e]) => {
        e.target.classList.toggle('visible', e.isIntersecting);
    }, { threshold: 0.2 });
    const ctaInner = document.querySelector('.cta-inner');
    if (ctaInner) ctaObserver.observe(ctaInner);

    /* ─────────────────────────────────────────────
       13. LINKS section
    ───────────────────────────────────────────── */
    const linksObserver = new IntersectionObserver(([e]) => {
        e.target.classList.toggle('visible', e.isIntersecting);
    }, { threshold: 0.2 });
    const linksGrid = document.querySelector('.links-grid');
    if (linksGrid) linksObserver.observe(linksGrid);

    /* ─────────────────────────────────────────────
       14. FLOATING CHARS — bubble float animation stagger
    ───────────────────────────────────────────── */
    document.querySelectorAll('.char-float').forEach((el, i) => {
        el.style.animationDuration = `${3 + i * 0.3}s`;
        el.style.animationDelay = `${i * 0.15}s`;
    });

});
