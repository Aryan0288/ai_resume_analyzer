const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { GoogleGenAI } = require("@google/genai");

admin.initializeApp();

// Initialize GoogleGenAI client using process.env.GEMINI_API_KEY
function getGenAI() {
  const apiKey = process.env.GEMINI_API_KEY || functions.config().gemini?.key;
  if (!apiKey) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "GEMINI_API_KEY environment variable is not set."
    );
  }
  return new GoogleGenAI({ apiKey });
}

/**
 * 1. analyzeResume — Evaluates resume text against a target career role using Gemini AI
 */
exports.analyzeResume = functions.https.onCall(async (data, context) => {
  const { resumeText, targetRole } = data;
  if (!resumeText) {
    throw new functions.https.HttpsError("invalid-argument", "resumeText is required.");
  }

  const ai = getGenAI();
  const prompt = `
You are an expert ATS Resume Coach and Senior Technical Recruiter.
Evaluate the following resume for the target role: "${targetRole || "Software Engineer"}".

Return ONLY valid JSON matching this exact structure:
{
  "healthScore": 85,
  "critiques": [
    {
      "id": "crit_1",
      "type": "weakness",
      "title": "Missing Quantifiable Metrics",
      "description": "Your bullet points describe tasks without metric outcomes.",
      "beforeText": "Original weak bullet text",
      "afterText": "Improved metric-driven bullet text"
    }
  ]
}

Resume Text:
"""
${resumeText}
"""
`;

  try {
    const response = await ai.models.generateContent({
      model: "gemini-1.5-flash",
      contents: prompt,
      config: { responseMimeType: "application/json" },
    });

    const parsed = JSON.parse(response.text);
    return parsed;
  } catch (err) {
    console.error("analyzeResume error:", err);
    throw new functions.https.HttpsError("internal", err.message);
  }
});

/**
 * 2. generateQuestions — Generates job-specific interview questions using Gemini AI
 */
exports.generateQuestions = functions.https.onCall(async (data, context) => {
  const { resumeText, category } = data;

  const ai = getGenAI();
  const prompt = `
Generate 5 targeted interview questions for the category: "${category || "Technical"}".
Target Role/Context: "${resumeText || "Software Engineer"}".

Return ONLY valid JSON matching this exact structure:
{
  "questions": [
    {
      "id": "q_1",
      "category": "${category || "Technical"}",
      "difficulty": "Medium",
      "text": "Question text here?",
      "context": "Context background",
      "savedAnswer": "",
      "isCompleted": false,
      "aiEvaluation": ""
    }
  ]
}
`;

  try {
    const response = await ai.models.generateContent({
      model: "gemini-1.5-flash",
      contents: prompt,
      config: { responseMimeType: "application/json" },
    });

    return JSON.parse(response.text);
  } catch (err) {
    console.error("generateQuestions error:", err);
    throw new functions.https.HttpsError("internal", err.message);
  }
});

/**
 * 3. evaluateAnswer — Evaluates user interview answer using Gemini AI
 */
exports.evaluateAnswer = functions.https.onCall(async (data, context) => {
  const { questionText, answerText } = data;

  const ai = getGenAI();
  const prompt = `
You are a Senior Bar Raiser Interviewer. Evaluate this answer to the question:
Question: "${questionText}"
User Answer: "${answerText}"

Return ONLY valid JSON matching this structure:
{
  "feedback": "Detailed AI Coach feedback evaluating STAR format, technical depth, and delivery.",
  "overallScore": 8.5,
  "subMetrics": {
    "Technical Accuracy": 9.0,
    "STAR Format": 8.0,
    "Clarity": 8.5
  }
}
`;

  try {
    const response = await ai.models.generateContent({
      model: "gemini-1.5-flash",
      contents: prompt,
      config: { responseMimeType: "application/json" },
    });

    return JSON.parse(response.text);
  } catch (err) {
    console.error("evaluateAnswer error:", err);
    throw new functions.https.HttpsError("internal", err.message);
  }
});

/**
 * 4. generateQuiz — Generates MCQ skill assessment quiz targeting skill gaps using Gemini AI
 */
exports.generateQuiz = functions.https.onCall(async (data, context) => {
  const { skills } = data;

  const ai = getGenAI();
  const prompt = `
Generate 3 multiple-choice skill assessment questions targeting these skills: ${JSON.stringify(skills || ["Flutter", "Dart"])}.

Return ONLY valid JSON matching this structure:
{
  "questions": [
    {
      "id": "qz_1",
      "text": "Question text?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctOptionIndex": 0,
      "difficulty": "Medium",
      "estimatedSeconds": 45,
      "coachExplanation": "Detailed explanation of why Option A is correct."
    }
  ]
}
`;

  try {
    const response = await ai.models.generateContent({
      model: "gemini-1.5-flash",
      contents: prompt,
      config: { responseMimeType: "application/json" },
    });

    return JSON.parse(response.text);
  } catch (err) {
    console.error("generateQuiz error:", err);
    throw new functions.https.HttpsError("internal", err.message);
  }
});

/**
 * 5. compileReport — Compiles consolidated AI career report & learning roadmap using Gemini AI
 */
exports.compileReport = functions.https.onCall(async (data, context) => {
  const { resumeText, targetRole } = data;

  const ai = getGenAI();
  const prompt = `
Compile a comprehensive Career Readiness Report for target role: "${targetRole || "Software Engineer"}".

Return ONLY valid JSON matching this structure:
{
  "overallReadinessIndex": 82,
  "executiveSummary": "Candidate demonstrates strong foundational skills with high potential.",
  "strengths": ["Strong Architecture Understanding", "Clean Code Focus"],
  "improvements": ["Needs metric outcomes on bullet points", "Deepen state management testing"],
  "roleCompatibilities": {
    "${targetRole || "Software Engineer"}": 88,
    "Mobile Lead": 75
  },
  "averageSalary": "$135,000 / yr",
  "salaryPercentile": "78th Percentile",
  "roadmap": [
    {
      "id": "step_1",
      "title": "Resume Metric Optimization",
      "description": "Quantify outcomes across work experience bullet points.",
      "status": "completed",
      "actionLabel": "View Corrections"
    },
    {
      "id": "step_2",
      "title": "Advanced State Management Assessment",
      "description": "Complete skill quiz on ProxyProvider state propagation.",
      "status": "unlocked",
      "actionLabel": "Take Quiz"
    }
  ]
}
`;

  try {
    const response = await ai.models.generateContent({
      model: "gemini-1.5-flash",
      contents: prompt,
      config: { responseMimeType: "application/json" },
    });

    return JSON.parse(response.text);
  } catch (err) {
    console.error("compileReport error:", err);
    throw new functions.https.HttpsError("internal", err.message);
  }
});
