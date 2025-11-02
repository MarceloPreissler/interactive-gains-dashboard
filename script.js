// TAB FUNCTIONALITY
document.querySelectorAll('.tab-button').forEach(btn => {
  btn.addEventListener('click', e => {
    const target = e.target.getAttribute('data-tab');
    document.querySelectorAll('.tab-button').forEach(b => b.classList.remove('active'));
    e.target.classList.add('active');
    document.querySelectorAll('.tab-content').forEach(tab => {
      tab.classList.remove('active');
      if (tab.id === target) tab.classList.add('active');
    });
  });
});

// UPLOAD FUNCTIONALITY
const uploadArea = document.getElementById('uploadArea');
const fileInput = document.getElementById('fileInput');
const fileStatus = document.getElementById('fileStatus');

uploadArea.addEventListener('click', () => fileInput.click());
uploadArea.addEventListener('dragover', e => {
  e.preventDefault();
  uploadArea.style.background = 'rgba(255,255,255,0.4)';
});
uploadArea.addEventListener('dragleave', e => {
  e.preventDefault();
  uploadArea.style.background = 'rgba(255,255,255,0.2)';
});
uploadArea.addEventListener('drop', e => {
  e.preventDefault();
  uploadArea.style.background = 'rgba(255,255,255,0.2)';
  handleFiles(e.dataTransfer.files);
});
fileInput.addEventListener('change', e => handleFiles(e.target.files));

function handleFiles(files) {
  if (!files.length) return;
  const file = files[0];
  fileStatus.textContent = 'Processing file...';
  fileStatus.className = 'file-status status-loading';

  const reader = new FileReader();
  reader.onload = e => {
    let data;
    try {
      if (file.name.endsWith('.csv')) data = parseCSV(e.target.result);
      else if (file.name.endsWith('.xlsx') || file.name.endsWith('.xls')) data = parseExcel(e.target.result);
      else if (file.name.endsWith('.json')) data = JSON.parse(e.target.result);
      fileStatus.textContent = `File "${file.name}" loaded successfully (${data.length} rows).`;
      fileStatus.className = 'file-status status-success';
      console.log('Parsed Data:', data.slice(0, 3));
      // Save parsed data globally and update metrics
      window.dashboardData = data;
      updateMetrics(data);
    } catch (err) {
      fileStatus.textContent = 'Error parsing file: ' + err.message;
      fileStatus.className = 'file-status status-error';
    }
  };
  if (file.name.endsWith('.xlsx') || file.name.endsWith('.xls')) reader.readAsArrayBuffer(file);
  else reader.readAsText(file);
}

function parseCSV(csvText) {
  const [header, ...lines] = csvText.trim().split('\n');
  const headers = header.split(',').map(h => h.trim());
  return lines.map(line => {
    const values = line.split(',');
    const obj = {};
    headers.forEach((h, i) => (obj[h] = values[i]));
    return obj;
  });
}

function parseExcel(arrayBuffer) {
  const workbook = XLSX.read(arrayBuffer, { type: 'array' });
  const sheet = workbook.Sheets[workbook.SheetNames[0]];
  return XLSX.utils.sheet_to_json(sheet);
}

// AUTO-LOAD DATA ON PAGE LOAD
document.addEventListener('DOMContentLoaded', () => {
  loadDataFromRepo();
});

async function loadDataFromRepo() {
  try {
    fileStatus.textContent = 'Loading latest data...';
    fileStatus.className = 'file-status status-loading';

    const response = await fetch('data/dashboard_data.csv');
    if (!response.ok) {
      throw new Error('Data file not found. Please upload a file manually.');
    }

    const csvText = await response.text();
    const data = parseCSV(csvText);

    window.dashboardData = data;
    updateMetrics(data);

    fileStatus.textContent = `Auto-loaded latest data (${data.length} rows, last updated: ${new Date().toLocaleDateString()})`;
    fileStatus.className = 'file-status status-success';
  } catch (error) {
    fileStatus.textContent = 'No data file found. Please upload a CSV file to view metrics.';
    fileStatus.className = 'file-status status-error';
    console.warn('Auto-load failed:', error.message);
  }
}

// Compute and display metrics across tabs based on uploaded data
function updateMetrics(data) {
  // Validate that data exists and is an array
  if (!data || !Array.isArray(data) || data.length === 0) {
    return;
  }

  /**
   * Helper functions to format numbers and percentages.  These helpers mirror
   * the formatting used throughout the app: comma separators for numbers and
   * one decimal place for percentages.
   */
  function formatNumber(value) {
    return value.toLocaleString('en-US');
  }
  function formatPercent(value) {
    return `${value.toFixed(1)}%`;
  }

  // Determine the most recent year and month present in the data
  let latestYear = 0;
  let latestMonth = 0;
  data.forEach(row => {
    const yr = Number(row.year);
    const mon = Number(row.month);
    if (yr > latestYear || (yr === latestYear && mon > latestMonth)) {
      latestYear = yr;
      latestMonth = mon;
    }
  });

  // Elements for the three metric sections
  const overviewElem = document.getElementById('overviewMetrics');
  const monthlyElem = document.getElementById('monthlyMetrics');
  const ytdElem = document.getElementById('ytdMetrics');

  // Precompute YTD and monthly metrics up front so they can be shared across sections.
  const ytdData = data.filter(row => Number(row.year) === latestYear);
  const ytdPriorData = data.filter(row => Number(row.year) === latestYear - 1);
  const ytdGains = ytdData.reduce((sum, row) => sum + (Number(row.gains) || 0), 0);
  const ytdLosses = ytdData.reduce((sum, row) => sum + (Number(row.losses) || 0), 0);
  const ytdPlan = ytdData.reduce((sum, row) => sum + (Number(row.plan) || 0), 0);
  const ytdPrior = ytdPriorData.reduce((sum, row) => sum + (Number(row.gains) || 0), 0);
  const ytdNet = ytdGains - ytdLosses;
  const ytdVsPlan = ytdGains - ytdPlan;
  const ytdVsPlanPct = ytdPlan !== 0 ? (ytdVsPlan / ytdPlan) * 100 : 0;
  const ytdVsPrior = ytdGains - ytdPrior;
  const ytdVsPriorPct = ytdPrior !== 0 ? (ytdVsPrior / ytdPrior) * 100 : 0;

  const monthlyData = data.filter(row => Number(row.year) === latestYear && Number(row.month) === latestMonth);
  const monthlyPriorData = data.filter(row => Number(row.year) === latestYear - 1 && Number(row.month) === latestMonth);
  const mtdGains = monthlyData.reduce((sum, row) => sum + (Number(row.gains) || 0), 0);
  const mtdLosses = monthlyData.reduce((sum, row) => sum + (Number(row.losses) || 0), 0);
  const mtdPlan = monthlyData.reduce((sum, row) => sum + (Number(row.plan) || 0), 0);
  const mtdPrior = monthlyPriorData.reduce((sum, row) => sum + (Number(row.gains) || 0), 0);
  const mtdNet = mtdGains - mtdLosses;
  const mtdVsPlan = mtdGains - mtdPlan;
  const mtdVsPlanPct = mtdPlan !== 0 ? (mtdVsPlan / mtdPlan) * 100 : 0;
  const mtdVsPrior = mtdGains - mtdPrior;
  const mtdVsPriorPct = mtdPrior !== 0 ? (mtdVsPrior / mtdPrior) * 100 : 0;

  // ---- OVERVIEW (YTD + MTD summary) ----
  if (overviewElem) {
    // Clear previous content
    overviewElem.innerHTML = '';
    overviewElem.classList.add('metric-section');

    // Build HTML for overview metrics using precomputed values
    const overviewHtml = [];
    overviewHtml.push(`<p><strong>Year-to-Date (${latestYear})</strong></p>`);
    overviewHtml.push(`<p>Total Gains: ${formatNumber(ytdGains)} | Total Plan: ${formatNumber(ytdPlan)} | Net Gains: ${formatNumber(ytdNet)}</p>`);
    overviewHtml.push(`<p>vs Plan: <span class="${ytdVsPlan >= 0 ? 'positive' : 'negative'}">${formatNumber(ytdVsPlan)} (${formatPercent(ytdVsPlanPct)})</span></p>`);
    overviewHtml.push(`<p>vs Prior Year: <span class="${ytdVsPrior >= 0 ? 'positive' : 'negative'}">${formatNumber(ytdVsPrior)} (${formatPercent(ytdVsPriorPct)})</span></p>`);
    overviewHtml.push('<br />');
    overviewHtml.push(`<p><strong>Current Month (${latestYear}-${String(latestMonth).padStart(2, '0')})</strong></p>`);
    overviewHtml.push(`<p>Gains: ${formatNumber(mtdGains)} | Plan: ${formatNumber(mtdPlan)} | Losses: ${formatNumber(mtdLosses)} | Net: ${formatNumber(mtdNet)}</p>`);
    overviewHtml.push(`<p>vs Plan: <span class="${mtdVsPlan >= 0 ? 'positive' : 'negative'}">${formatNumber(mtdVsPlan)} (${formatPercent(mtdVsPlanPct)})</span></p>`);
    overviewHtml.push(`<p>vs Prior Year: <span class="${mtdVsPrior >= 0 ? 'positive' : 'negative'}">${formatNumber(mtdVsPrior)} (${formatPercent(mtdVsPriorPct)})</span></p>`);
    overviewElem.innerHTML = overviewHtml.join('');
  }

  // ---- MONTHLY (single period details) ----
  if (monthlyElem) {
    monthlyElem.innerHTML = '';
    monthlyElem.classList.add('metric-section');
    const monthlyHtml = [];
    monthlyHtml.push(`<p><strong>Performance for ${latestYear}-${String(latestMonth).padStart(2, '0')}</strong></p>`);
    monthlyHtml.push(`<p>Gains: ${formatNumber(mtdGains)} | Plan: ${formatNumber(mtdPlan)} | Losses: ${formatNumber(mtdLosses)} | Net: ${formatNumber(mtdNet)}</p>`);
    monthlyHtml.push(`<p>vs Plan: <span class="${mtdVsPlan >= 0 ? 'positive' : 'negative'}">${formatNumber(mtdVsPlan)} (${formatPercent(mtdVsPlanPct)})</span></p>`);
    monthlyHtml.push(`<p>vs Prior Year: <span class="${mtdVsPrior >= 0 ? 'positive' : 'negative'}">${formatNumber(mtdVsPrior)} (${formatPercent(mtdVsPriorPct)})</span></p>`);
    monthlyElem.innerHTML = monthlyHtml.join('');
  }

  // ---- YEAR-TO-DATE (aggregated details) ----
  if (ytdElem) {
    ytdElem.innerHTML = '';
    ytdElem.classList.add('metric-section');
    const ytdHtml = [];
    ytdHtml.push(`<p><strong>Year ${latestYear} Performance</strong></p>`);
    ytdHtml.push(`<p>Gains: ${formatNumber(ytdGains)} | Plan: ${formatNumber(ytdPlan)} | Losses: ${formatNumber(ytdLosses)} | Net: ${formatNumber(ytdNet)}</p>`);
    ytdHtml.push(`<p>vs Plan: <span class="${ytdVsPlan >= 0 ? 'positive' : 'negative'}">${formatNumber(ytdVsPlan)} (${formatPercent(ytdVsPlanPct)})</span></p>`);
    ytdHtml.push(`<p>vs Prior Year: <span class="${ytdVsPrior >= 0 ? 'positive' : 'negative'}">${formatNumber(ytdVsPrior)} (${formatPercent(ytdVsPriorPct)})</span></p>`);
    ytdElem.innerHTML = ytdHtml.join('');
  }
}
