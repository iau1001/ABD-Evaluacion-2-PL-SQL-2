
-- ToDo: Preparar para excepci�n AUTOCAR_COMPLETO

drop table modelos cascade constraints;
drop table autocares cascade constraints;
drop table recorridos cascade constraints;
drop table viajes cascade constraints;
drop table tickets cascade constraints;

create table modelos(
 idModelo integer primary key,
 nplazas integer
);

create table autocares(
  idAutocar   integer primary key,
  modelo      integer references modelos,
  kms         integer not null
);

create table recorridos(
   idRecorrido      integer primary key,
   estacionOrigen   varchar(15) not null,
   estacionDestino  varchar(15) not null,
   kms              numeric(6,2) not null,
   precio           numeric(5,2) not null
);

create table viajes(
 idViaje     	integer primary key,
 idAutocar   	integer references autocares  not null,
 idRecorrido 	integer references recorridos not null,
 fecha 		    date not null,
 nPlazasLibres	integer not null,
 Conductor    varchar(25) not null,
 unique (idRecorrido, fecha) 
);

drop sequence seq_viajes;
create sequence seq_viajes;

create table tickets(
 idTicket 	integer primary key,
 idViaje  	integer references viajes not null,
 fechaCompra    date not null,
 cantidad       integer not null,
 precio		numeric(5,2) not null
);
drop sequence seq_tickets;
create sequence seq_tickets;

insert into modelos (idModelo, nPlazas) values ( 1, 40 );  
insert into modelos (idModelo, nPlazas) values ( 2, 15 );  
insert into modelos (idModelo, nPlazas) values ( 3, 35 );  

insert into autocares ( idAutocar, modelo, kms) values (1, 1, 1000);
insert into autocares ( idAutocar, modelo, kms) values (2, 1, 7500);
insert into autocares ( idAutocar, modelo, kms) values (3, 2, 2000);
insert into autocares ( idAutocar, kms) values (4, 1000);

insert into recorridos (idRecorrido, estacionOrigen, estacionDestino, kms, precio)
values (1, 'Burgos', 'Madrid', 201, 10 );
insert into recorridos (idRecorrido, estacionOrigen, estacionDestino, kms, precio)
values (2, 'Burgos', 'Madrid', 200, 12);
insert into recorridos (idRecorrido, estacionOrigen, estacionDestino, kms, precio)
values (3, 'Madrid', 'Burgos', 200, 10);
insert into recorridos (idRecorrido, estacionOrigen, estacionDestino, kms, precio)
values (4, 'Leon', 'Zamora', 150, 6);

insert into viajes (idViaje, idAutocar, idRecorrido, fecha, nPlazasLibres,  Conductor)
values (seq_viajes.nextval, 1, 1, DATE '2009-1-22', 30, 'Juan');
insert into viajes (idViaje, idAutocar, idRecorrido, fecha, nPlazasLibres,  Conductor)
values (seq_viajes.nextval, 1, 1, trunc(current_date)+1, 38, 'Javier');
insert into viajes (idViaje, idAutocar, idRecorrido, fecha, nPlazasLibres,  Conductor)
values (seq_viajes.nextval, 1, 1, trunc(current_date)+7, 10, 'Maria');
insert into viajes (idViaje, idAutocar, idRecorrido, fecha, nPlazasLibres,  Conductor)
values(seq_viajes.nextval, 2, 4, trunc(current_date)+7, 40, 'Ana');


commit;
--exit;


create or replace procedure crearViaje( m_idRecorrido int, m_idAutocar int, m_fecha date, m_conductor varchar) is

aut_modelo autocares.modelo%type;
num_plazas modelos.nplazas%type;
num_viajes integer;
num_rec integer;
num_dupl integer;

begin
    begin
        --Se obtiene el modelo del autocar. Si el autocar no existe lanza no_data_found
        select modelo into aut_modelo 
        from autocares where autocares.idAutocar=m_idAutocar;
		--Si no tiene modelo se asigna el num. de plazas a 25
        if aut_modelo IS NULL then
            num_plazas := 25;
        --Si no, se obtiene el num. de plazas
        else
            select nplazas into num_plazas
            from autocares join modelos on autocares.modelo=modelos.idModelo
            where autocares.idAutocar=m_idAutocar;
        end if;
	--Se captura la excepci�n y se lanza el error -20002
    exception
        when no_data_found then
        rollback;
        raise_application_error(-20002,'El autocar no existe');
    end;
	
	--Se comprueba si el autocar est� ocupado
    select count(*) into num_viajes
    from viajes where idAutocar=m_idAutocar and fecha=m_fecha;
    --Si est� ocupado se lanza el error -20003
    if num_viajes!=0 then
        rollback;
        raise_application_error(-20003,'Autocar ocupado');
    end if;
	
	--Se comprueba si existe el recorrido
    select count(*) into num_rec
    from recorridos where idRecorrido=m_idRecorrido;
    --Si no existe, se lanza el error -20001
    if num_rec = 0 then
        rollback;
        raise_application_error(-20001,'El recorrido no existe');
    end if;
	
	--Se comprueba si se duplica el viaje
    select count(*) into num_dupl
    from viajes where idRecorrido=m_idRecorrido and fecha=m_fecha;
    --Si es un viaje duplicado, se lanza el error -20004
    if num_dupl != 0 then
        rollback;
        raise_application_error(-20004,'Viaje duplicado');
    end if;
	
	--Se cumplen todos los requisitos,se inserta el viaje
    insert into viajes (idViaje, idAutocar, idRecorrido, fecha, nPlazasLibres,  Conductor)
    values (seq_viajes.nextval,m_idAutocar,m_idRecorrido,m_fecha,num_plazas,m_conductor);
    commit;
	
--Captura la excepci�n, realiza rollback y la relanza    
exception
    when others then
        rollback;
        raise;
end;
/

set serveroutput on


create or replace procedure test_crearViaje is
begin
  
  --Caso 1: RECORRIDO_INEXISTENTE
  begin
    crearViaje(11, 2, trunc(current_date), 'Juanito');
    dbms_output.put_line('Mal no detecta RECORRIDO_INEXISTENTE');
  exception
    when others then
      if sqlcode = -20001 then
        dbms_output.put_line('OK: Detecta RECORRIDO_INEXISTENTE: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta RECORRIDO_INEXISTENTE: '||sqlerrm);
      end if;
  end;
  
  
  --Caso 2: AUTOCAR_INEXISTENTE
   begin
    crearViaje(1, 22, trunc(current_date), 'Juanito');
    dbms_output.put_line('Mal no detecta AUTOCAR_INEXISTENTE');
  exception
    when others then
      if sqlcode = -20002 then
        dbms_output.put_line('OK: Detecta AUTOCAR_INEXISTENTE: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta AUTOCAR_INEXISTENTE: '||sqlerrm);
      end if;
  end;
  
  
  --Caso 3: AUTOCAR_OCUPADO
   begin
    crearViaje(2, 1, trunc(current_date)+1, 'Juanito');
    dbms_output.put_line('Mal no detecta AUTOCAR_OCUPADO');
  exception
    when others then
      if sqlcode = -20003 then
        dbms_output.put_line('OK: Detecta AUTOCAR_OCUPADO: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta AUTOCAR_OCUPADO: '||sqlerrm);
      end if;
  end;
  
  
  --Caso 4: VIAJE_DUPLICADO
   begin
    crearViaje(1, 2, trunc(current_date)+1, 'Juanito');
    dbms_output.put_line('Mal no detecta VIAJE_DUPLICADO');
  exception
    when others then
      if sqlcode = -20004 then
        dbms_output.put_line('OK: Detecta VIAJE_DUPLICADO: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta VIAJE_DUPLICADO: '||sqlerrm);
      end if;
  end;
  
  
  --Caso 4: Crea un viaje OK
  begin
    crearViaje(1, 1, trunc(current_date)+3, 'Pedrito');
    dbms_output.put_line('Parece OK Crea un viaje v�lido');
  exception
    when others then
        dbms_output.put_line('MAL Crea un viaje v�lido: '||sqlerrm);
  end;
  
  
  --Caso 5: Crea un viaje OK con autcar sin modelo
  begin
    crearViaje(1, 4, trunc(current_date)+4, 'Jorgito');
    dbms_output.put_line('Parece OK Crea un viaje v�lido sin modelo');
  exception
    when others then
        dbms_output.put_line('MAL Crea un viaje v�lido sin modelo: '||sqlerrm);
  end;
  
  
  --Caso FINAL: Todo OK
  declare
    varContenidoReal varchar(500);
    varContenidoEsperado    varchar(500):= 
      '11122/01/0930Juan#211' || to_char(trunc(current_date)+1,'DD/MM/YY') || '38Javier#311' || to_char(trunc(current_date)+7,'DD/MM/YY') || '10Maria#424' || to_char(trunc(current_date)+7,'DD/MM/YY') || '40Ana#511' || to_char(trunc(current_date)+3,'DD/MM/YY') || '40Pedrito#641' || to_char(trunc(current_date)+4,'DD/MM/YY') || '25Jorgito';
    
  begin
    rollback; --por si se olvida commit de matricular
    
    SELECT listagg( idViaje || idAutocar || idRecorrido || fecha || nPlazasLibres || Conductor, '#')
        within group (order by idViaje)
    into varContenidoReal
    FROM viajes;
    
    if varContenidoReal=varContenidoEsperado then
      dbms_output.put_line('OK: S� que modifica bien la BD.'); 
    else
      dbms_output.put_line('Mal no modifica bien la BD.'); 
      dbms_output.put_line('Contenido real:     '||varContenidoReal); 
      dbms_output.put_line('Contenido esperado: '||varContenidoEsperado); 
    end if;
    
  exception
    when others then
      dbms_output.put_line('Mal caso todo OK: '||sqlerrm);
  end;
  
end;
/

begin
  test_crearViaje;
end;
/

