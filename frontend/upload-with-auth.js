// Tab switching
document.querySelectorAll('.tab').forEach(tab => {
    tab.addEventListener('click', () => {
        const tabName = tab.dataset.tab;

        document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));

        tab.classList.add('active');
        document.getElementById(tabName).classList.add('active');
    });
});

// Utility functions
function showStatus(elementId, message, type) {
    const status = document.getElementById(elementId);
    status.textContent = message;
    status.className = `status ${type}`;
    status.style.display = 'block';
}

function updateProgress(barId, percent) {
    const bar = document.getElementById(barId);
    bar.style.width = percent + '%';
    bar.textContent = Math.round(percent) + '%';
    bar.parentElement.style.display = 'block';
}

function formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

function showFileInfo(infoId, file) {
    const info = document.getElementById(infoId);
    info.innerHTML = `
        <div><strong>File:</strong> ${file.name}</div>
        <div><strong>Size:</strong> ${formatBytes(file.size)}</div>
        <div><strong>Type:</strong> ${file.type || 'unknown'}</div>
    `;
    info.style.display = 'block';
}

// ============================================
// STANDARD SIGNED URL UPLOAD
// ============================================

let standardFile = null;

const standardDropZone = document.getElementById('standardDropZone');
const standardFileInput = document.getElementById('standardFileInput');
const standardUploadBtn = document.getElementById('standardUploadBtn');

standardDropZone.addEventListener('click', () => standardFileInput.click());

standardDropZone.addEventListener('dragover', (e) => {
    e.preventDefault();
    standardDropZone.classList.add('dragging');
});

standardDropZone.addEventListener('dragleave', () => {
    standardDropZone.classList.remove('dragging');
});

standardDropZone.addEventListener('drop', (e) => {
    e.preventDefault();
    standardDropZone.classList.remove('dragging');
    const files = e.dataTransfer.files;
    if (files.length > 0) {
        standardFile = files[0];
        showFileInfo('standardFileInfo', standardFile);
        standardUploadBtn.style.display = 'block';
    }
});

standardFileInput.addEventListener('change', (e) => {
    if (e.target.files.length > 0) {
        standardFile = e.target.files[0];
        showFileInfo('standardFileInfo', standardFile);
        standardUploadBtn.style.display = 'block';
    }
});

standardUploadBtn.addEventListener('click', async () => {
    if (!standardFile) return;

    const backendUrl = document.getElementById('backendUrl').value;

    try {
        standardUploadBtn.disabled = true;
        showStatus('standardStatus', 'Generating signed URL...', 'info');

        // Check if user is logged in
        if (!window.currentUserToken) {
            showStatus('standardStatus', '❌ Please sign in first', 'error');
            standardUploadBtn.disabled = false;
            return;
        }

        // Step 1: Get signed URL from backend (WITH AUTH TOKEN!)
        const response = await fetch(`${backendUrl}/api/generate-signed-url`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${window.currentUserToken}`  // 🔑 AUTH TOKEN!
            },
            body: JSON.stringify({
                filename: standardFile.name,
                content_type: standardFile.type
            })
        });

        if (!response.ok) {
            throw new Error(`Failed to generate signed URL: ${response.statusText}`);
        }

        const data = await response.json();
        showStatus('standardStatus', `Uploading to Cloud Storage...`, 'info');

        // Step 2: Upload directly to Cloud Storage using signed URL
        const xhr = new XMLHttpRequest();

        xhr.upload.addEventListener('progress', (e) => {
            if (e.lengthComputable) {
                const percent = (e.loaded / e.total) * 100;
                updateProgress('standardProgressBar', percent);
            }
        });

        xhr.addEventListener('load', () => {
            if (xhr.status === 200) {
                showStatus('standardStatus',
                    `✅ Upload successful! File: ${data.filename}`,
                    'success');
                updateProgress('standardProgressBar', 100);
            } else {
                showStatus('standardStatus',
                    `❌ Upload failed: ${xhr.statusText}`,
                    'error');
            }
            standardUploadBtn.disabled = false;
        });

        xhr.addEventListener('error', () => {
            showStatus('standardStatus', '❌ Upload failed: Network error', 'error');
            standardUploadBtn.disabled = false;
        });

        xhr.open('PUT', data.signed_url);
        xhr.setRequestHeader('Content-Type', standardFile.type);
        xhr.send(standardFile);

    } catch (error) {
        showStatus('standardStatus', `❌ Error: ${error.message}`, 'error');
        standardUploadBtn.disabled = false;
    }
});

// ============================================
// RESUMABLE UPLOAD
// ============================================

let resumableFile = null;
let resumableUploadUrl = null;
let resumableXhr = null;
let uploadedBytes = 0;

const resumableDropZone = document.getElementById('resumableDropZone');
const resumableFileInput = document.getElementById('resumableFileInput');
const resumableUploadBtn = document.getElementById('resumableUploadBtn');
const resumablePauseBtn = document.getElementById('resumablePauseBtn');
const resumableResumeBtn = document.getElementById('resumableResumeBtn');

resumableDropZone.addEventListener('click', () => resumableFileInput.click());

resumableDropZone.addEventListener('dragover', (e) => {
    e.preventDefault();
    resumableDropZone.classList.add('dragging');
});

resumableDropZone.addEventListener('dragleave', () => {
    resumableDropZone.classList.remove('dragging');
});

resumableDropZone.addEventListener('drop', (e) => {
    e.preventDefault();
    resumableDropZone.classList.remove('dragging');
    const files = e.dataTransfer.files;
    if (files.length > 0) {
        resumableFile = files[0];
        showFileInfo('resumableFileInfo', resumableFile);
        resumableUploadBtn.style.display = 'block';
    }
});

resumableFileInput.addEventListener('change', (e) => {
    if (e.target.files.length > 0) {
        resumableFile = e.target.files[0];
        showFileInfo('resumableFileInfo', resumableFile);
        resumableUploadBtn.style.display = 'block';
    }
});

resumableUploadBtn.addEventListener('click', async () => {
    if (!resumableFile) return;

    const backendUrl = document.getElementById('backendUrl').value;

    try {
        resumableUploadBtn.disabled = true;
        showStatus('resumableStatus', 'Generating resumable upload URL...', 'info');

        // Check if user is logged in
        if (!window.currentUserToken) {
            showStatus('resumableStatus', '❌ Please sign in first', 'error');
            resumableUploadBtn.disabled = false;
            return;
        }

        // Step 1: Get resumable upload URL from backend (WITH AUTH TOKEN!)
        const response = await fetch(`${backendUrl}/api/generate-resumable-url`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${window.currentUserToken}`  // 🔑 AUTH TOKEN!
            },
            body: JSON.stringify({
                filename: resumableFile.name,
                content_type: resumableFile.type
            })
        });

        if (!response.ok) {
            throw new Error(`Failed to generate resumable URL: ${response.statusText}`);
        }

        const data = await response.json();
        resumableUploadUrl = data.resumable_url;

        // Step 2: Start resumable upload
        uploadResumable();

    } catch (error) {
        showStatus('resumableStatus', `❌ Error: ${error.message}`, 'error');
        resumableUploadBtn.disabled = false;
    }
});

function uploadResumable() {
    showStatus('resumableStatus', 'Uploading to Cloud Storage...', 'info');

    resumableXhr = new XMLHttpRequest();

    resumableXhr.upload.addEventListener('progress', (e) => {
        if (e.lengthComputable) {
            const percent = (e.loaded / e.total) * 100;
            updateProgress('resumableProgressBar', percent);
        }
    });

    resumableXhr.addEventListener('load', () => {
        if (resumableXhr.status === 200) {
            showStatus('resumableStatus',
                '✅ Resumable upload successful!',
                'success');
            updateProgress('resumableProgressBar', 100);
            resumablePauseBtn.style.display = 'none';
            resumableResumeBtn.style.display = 'none';
            resumableUploadBtn.disabled = false;
        } else {
            showStatus('resumableStatus',
                `❌ Upload failed: ${resumableXhr.statusText}`,
                'error');
        }
    });

    resumableXhr.addEventListener('error', () => {
        showStatus('resumableStatus',
            '⚠️ Upload paused due to error. Click Resume to retry.',
            'error');
        resumablePauseBtn.style.display = 'none';
        resumableResumeBtn.style.display = 'block';
    });

    resumableXhr.open('PUT', resumableUploadUrl);
    resumableXhr.setRequestHeader('Content-Type', resumableFile.type);
    resumableXhr.send(resumableFile);

    resumablePauseBtn.style.display = 'block';
    resumableUploadBtn.style.display = 'none';
}

resumablePauseBtn.addEventListener('click', () => {
    if (resumableXhr) {
        resumableXhr.abort();
        showStatus('resumableStatus', '⏸️ Upload paused. Click Resume to continue.', 'info');
        resumablePauseBtn.style.display = 'none';
        resumableResumeBtn.style.display = 'block';
    }
});

resumableResumeBtn.addEventListener('click', () => {
    showStatus('resumableStatus', 'Resuming upload...', 'info');
    uploadResumable();
    resumableResumeBtn.style.display = 'none';
});
