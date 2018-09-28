create or replace PACKAGE projet
AS

  PROCEDURE addUser (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2);

  PROCEDURE creerCourse (
    p_courseID IN NUMBER,
    p_clientID in NUMBER,
    p_addressDepart in VARCHAR2,
    p_addressDestination in VARCHAR2,
    p_immediat in CHAR,
    p_nbpassager in NUMBER
  );
    
  PROCEDURE assignerCourse (
    p_courseID IN NUMBER);
    
  PROCEDURE updateDispo (
    p_chauffeurID IN NUMBER,
    p_indice in NUMBER);    

  PROCEDURE trouverCourse (
    p_chauffeurID IN NUMBER);

  PROCEDURE FinCourse (
    p_courseID IN NUMBER);
    
  PROCEDURE miseAjourAttente (
    p_courseID IN NUMBER,
    p_indice IN NUMBER);

  PROCEDURE prendreCourse (
    p_courseID IN NUMBER,
    p_chauffeurID IN NUMBER);

  FUNCTION trouverChauffeur (
    p_courseID IN NUMBER)
  RETURN NUMBER;
  
  FUNCTION get_hash (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2)
  RETURN VARCHAR2;

  FUNCTION login (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2)
  RETURN BOOLEAN;

END projet;




