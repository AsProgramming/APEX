create or replace PACKAGE projet
AS

  PROCEDURE addUser (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2,
    p_email IN VARCHAR2);

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



--PACKAGE BODY
create or replace PACKAGE BODY projet
AS

  PROCEDURE creerCourse (
    p_courseID IN NUMBER,
    p_clientID in NUMBER,
    p_addressDepart in VARCHAR2,
    p_addressDestination in VARCHAR2,
    p_immediat in CHAR,
    p_nbpassager in NUMBER
  )
  AS
      
  BEGIN
  
  INSERT INTO COURSE1 VALUES(p_courseID, null, null, null,
                             p_addressDepart, p_addressDestination, 
                             p_nbpassager, null, null, p_immediat, null,
                             p_clientID, null, systimestamp, sysdate);
  assignerCourse(p_courseID);                           
  END creerCourse;

  PROCEDURE assignerCourse (
    p_courseID IN NUMBER)
  AS 
    v_chauffeur number;
    BEGIN
        v_chauffeur := trouverChauffeur(p_courseID);
        IF v_chauffeur != -1
            then prendreCourse(p_courseID, v_chauffeur);
            --else if dojob to check disponbible every minute or 2
         end if;   
  END assignerCourse;

  PROCEDURE prendreCourse (
    p_courseID IN NUMBER,
    p_chauffeurID IN NUMBER)
  AS 
    
    BEGIN
        UPDATE disponibilite1 set disponible = 'N'
        where CHAUFFEUR1_CHAUFFEUR_ID = p_chauffeurID;
        commit;
        
        dbms_output.put_line('assignation de course au chauffeur ' || p_chauffeurID);
        
        miseAjourAttente(p_courseID,1);
        UPDATE course1 set COURSE1.CHAUFFEUR1_CHAUFFEUR_ID = p_chauffeurID
        where course_id = p_courseID;
        commit;
  
  END prendreCourse;

  PROCEDURE FinCourse (
    p_courseID IN NUMBER)
  AS
    v_chauffeurID number;
    BEGIN
    SELECT chauffeur1_chauffeur_id into v_chauffeurID from course1 
    where course_id = p_courseID;
    
    miseAjourAttente(p_courseID,2);
    /* FOR TETSING PURPOSES*/
    UPDATE DISPONIBILITE1 set disponible = 'O' 
    where CHAUFFEUR1_CHAUFFEUR_ID =  v_chauffeurID;
    commit;
    
  END FinCourse;
  
  FUNCTION trouverChauffeur (
    p_courseID IN NUMBER)
  RETURN NUMBER
  AS
    v_chauffeurID number;
  BEGIN

    SELECT * into v_chauffeurID from (select CHAUFFEUR1_CHAUFFEUR_ID 
    from disponibilite1 where disponible = 'O' 
    order by temps_disponible asc) where rownum = 1;  
    
    dbms_output.put_line('on trouve le chauffeur '||v_chauffeurID);
    return v_chauffeurID;
    
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN 
            miseAjourAttente(p_courseID,0);
    RETURN -1;

  END trouverChauffeur;




  PROCEDURE miseAjourAttente (
    p_courseID IN NUMBER,
    p_indice IN NUMBER)
  AS
  
    BEGIN
    if p_indice = 0
        then 
        
        dbms_output.put_line('mise en att de course ' || p_courseID);
        
        update COURSE1 set enattente = 'O' where course_id = p_courseID;
        commit;
    elsif p_indice = 1
        then 
        dbms_output.put_line('Changement de status de la course ' || p_courseID);
        update COURSE1 set enattente = 'N' where course_id = p_courseID;
        commit;
    elsif p_indice = 2
        then 
        
        dbms_output.put_line('fin de course ' || p_courseID);
        update COURSE1 set immediat = 'N', end_time = systimestamp where course_id = p_courseID;
        commit;
    end if;
    END miseAjourAttente;
    
    
  PROCEDURE updateDispo (
    p_chauffeurID IN NUMBER,
    p_indice in NUMBER)
  AS
  
  BEGIN
  if p_indice = 0
    then 
    dbms_output.put_line('Chauffeur devient non dispo ' || p_chauffeurID);
    UPDATE DISPONIBILITE1 set disponible = 'N' 
    where chauffeur1_chauffeur_id = p_chauffeurID;
    commit;
  else
    dbms_output.put_line('Chauffeur est maintenant dispo ' || p_chauffeurID);
    UPDATE DISPONIBILITE1 set disponible = 'O', temps_disponible = systimestamp
    where chauffeur1_chauffeur_id = p_chauffeurID;
    commit;
    trouverCourse(p_chauffeurID);
  end if;  
    END updateDispo;
    
  PROCEDURE trouverCourse (
    p_chauffeurID IN NUMBER)
  AS
    v_courseID number;
  BEGIN
    SELECT * into v_courseID from (select COURSE_ID 
    from COURSE1 where enattente = 'O' and immediat = 'O'
    order by creer asc) where rownum = 1;  
    
    prendreCourse(v_courseID, p_chauffeurID);
    
    dbms_output.put_line('on trouve la course qui attente le plus longtemps '||v_courseID);
    
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN 
            dbms_output.put_line('Pas de course en attente');

  END trouverCourse;
  
  PROCEDURE addUser (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2,
    p_email IN VARCHAR2)
  AS
    v_username USAGER1.USERNAME%TYPE;

    BEGIN
    
      v_username := TRIM (UPPER (p_username));

      INSERT INTO USAGER1 (username, password, email)
      VALUES (v_username,
              get_hash (v_username, p_password),
             p_email);
      COMMIT;
  
      EXCEPTION
        WHEN OTHERS THEN ROLLBACK; 
        RAISE;

  END addUser;


  -- One-way hash du mot de passe. DBMS_OBFUSCATION_TOOLKIT est
  -- maintenant obsol�te -- vous pouvez am�liorer cette fonction
  -- avec DBMS_CYPTO. Cette fonction devrait �tre "wrapped" car
  -- l'algorithme est expos�.

  FUNCTION get_hash (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2)
  RETURN VARCHAR2

  AS

    v_password_hash USAGER1.PASSWORD%TYPE;
    v_salt VARCHAR2(100) := 'JOEBOBSKY12345';
    v_username USAGER1.USERNAME%TYPE;

  BEGIN
  
    v_username := TRIM (UPPER (p_username));

    v_password_hash := utl_raw.cast_to_raw(DBMS_OBFUSCATION_TOOLKIT.md5
      (input_string => p_password || substr(v_salt,10,13) || v_username ||
        substr(v_salt, 4,10)));

    RETURN v_password_hash;

  END get_hash;


  -- Voici la fonction appel�e par le mod�le d'authentification
  -- Cr��e � partir de "CUSTOM_AUTH". Peut �tre modifi�e pour ajouter
  -- date d'expiration, etc.

  FUNCTION login (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2)
  RETURN BOOLEAN

  AS

    v_username USAGER1.USERNAME%TYPE;
    v_password_hash VARCHAR2 (4000);
    v_count NUMBER;

  BEGIN

    v_username := TRIM (UPPER (p_username));

    SELECT  COUNT (*) INTO v_count
    FROM    USAGER1
    WHERE   UPPER (USERNAME) = v_username;

    IF v_count = 0
    THEN
      RETURN FALSE;
    END IF;

    -- Obtenir le mot de passe stock�

    SELECT  PASSWORD INTO v_password_hash
    FROM    USAGER1
    WHERE   UPPER (USERNAME) = v_username;

    IF v_password_hash = get_hash (v_username, p_password)
    THEN
      RETURN TRUE;
    END IF;

    RETURN FALSE;

  END login;  
  
  
  
END projet;


