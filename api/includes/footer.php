</main>

<footer class="text-center text-muted py-3 bg-white border-top small">
    <div class="container-fluid px-4 d-flex flex-column flex-sm-row justify-content-between align-items-center gap-2">
        <span>© 2026 <strong>Net-Portal</strong>. Network Usage Monitoring System.</span>
        <span class="text-secondary opacity-75">NetUsage Hub · Kisii Operations</span>
    </div>
</footer>

<?php if (!empty($_SESSION['flash'])): ?>
    <div class="toast-notice shadow" id="systemToast">
        <i class="fa fa-info-circle text-primary"></i>
        <span><?= e($_SESSION['flash']); unset($_SESSION['flash']); ?></span>
        <button type="button" class="btn-close btn-close-white btn-sm ms-2" onclick="this.parentElement.remove()" aria-label="Close"></button>
    </div>
<?php endif; ?>

<!-- Bootstrap 5 Bundle JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
