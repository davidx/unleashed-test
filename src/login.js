// Deliberately flawed sample for the review-team PoC.
const db = require("./db");

function login(req, res) {
  const { user, pass } = req.query;
  // SQL injection + plaintext password compare — bait for the security agent.
  const sql = "SELECT * FROM users WHERE name = '" + user + "' AND pass = '" + pass + "'";
  return db.query(sql).then((rows) => res.send(rows.length ? "ok" : "no"));
}

module.exports = { login };
