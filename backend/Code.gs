/**
 * Employee Request Management System (ERMS) - Google Apps Script Web App API Backend
 * Connects Flutter Mobile App -> Google Apps Script -> Google Sheets Database
 */

const SHEET_NAME = 'Requests';

function doGet(e) {
  const action = e.parameter.action;
  const employeeEmail = e.parameter.employeeEmail;
  const requestId = e.parameter.requestId;

  if (action === 'getRequests') {
    return handleGetRequests(employeeEmail);
  } else if (action === 'getRequestById') {
    return handleGetRequestById(requestId);
  }

  return createJsonResponse({ status: 'error', message: 'Invalid action' });
}

function doPost(e) {
  try {
    const postData = JSON.parse(e.postData.contents);
    const action = postData.action;
    const payload = postData.payload;

    if (action === 'createRequest') {
      return handleCreateRequest(payload);
    } else if (action === 'cancelRequest') {
      return handleCancelRequest(postData.requestId);
    }

    return createJsonResponse({ status: 'error', message: 'Unknown post action' });
  } catch (err) {
    return createJsonResponse({ status: 'error', message: err.toString() });
  }
}

function handleGetRequests(employeeEmail) {
  const sheet = getOrCreateSheet();
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) {
    return createJsonResponse({ status: 'success', requests: [] });
  }

  const headers = data[0];
  const requests = [];

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const email = row[3]; // Employee Email column
    if (!employeeEmail || email.toLowerCase() === employeeEmail.toLowerCase()) {
      requests.push({
        requestId: row[0],
        employeeId: row[1],
        employeeName: row[2],
        employeeEmail: row[3],
        department: row[4],
        managerEmail: row[5],
        requestType: row[6],
        requestData: JSON.parse(row[7] || '{}'),
        submittedAt: row[8],
        status: row[9],
        approvedAt: row[10] || null,
        approver: row[11] || null,
        rejectionReason: row[12] || null,
        attachments: JSON.parse(row[13] || '[]'),
        approvalHistory: JSON.parse(row[14] || '[]')
      });
    }
  }

  return createJsonResponse({ status: 'success', requests: requests });
}

function handleCreateRequest(payload) {
  const sheet = getOrCreateSheet();
  
  // Format: REQ-YYYY-XXXXXX
  const requestId = payload.requestId || ('REQ-' + new Date().getFullYear() + '-' + Math.floor(100000 + Math.random() * 900000));
  
  sheet.appendRow([
    requestId,
    payload.employeeId,
    payload.employeeName,
    payload.employeeEmail,
    payload.department,
    payload.managerEmail,
    payload.requestType,
    JSON.stringify(payload.requestData || {}),
    payload.submittedAt || new Date().toISOString(),
    payload.status || 'pendingManagerApproval',
    payload.approvedAt || '',
    payload.approver || '',
    payload.rejectionReason || '',
    JSON.stringify(payload.attachments || []),
    JSON.stringify(payload.approvalHistory || [])
  ]);

  // Send Email Notification to Reporting Manager
  try {
    MailApp.sendEmail({
      to: payload.managerEmail,
      subject: `[ERMS] New ${payload.requestType} Approval Required (${requestId})`,
      htmlBody: `
        <h3>New Employee Request Submitted</h3>
        <p><b>Employee:</b> ${payload.employeeName} (${payload.employeeEmail})</p>
        <p><b>Request ID:</b> ${requestId}</p>
        <p><b>Type:</b> ${payload.requestType}</p>
        <p>Please log into ERMS portal to approve or reject this request.</p>
      `
    });
  } catch (e) {
    Logger.log('Email notify failed: ' + e.toString());
  }

  return createJsonResponse({
    status: 'success',
    requestId: requestId,
    request: payload
  });
}

function getOrCreateSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(SHEET_NAME);
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_NAME);
    sheet.appendRow([
      'Request ID', 'Employee ID', 'Employee Name', 'Employee Email',
      'Department', 'Manager Email', 'Request Type', 'Request Details JSON',
      'Submission Date', 'Status', 'Approval Date', 'Approver',
      'Rejection Reason', 'Attachments JSON', 'Approval History JSON'
    ]);
  }
  return sheet;
}

function createJsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
