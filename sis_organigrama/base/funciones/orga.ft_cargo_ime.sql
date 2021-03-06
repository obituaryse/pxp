CREATE OR REPLACE FUNCTION orga.ft_cargo_ime (
  p_administrador integer,
  p_id_usuario integer,
  p_tabla varchar,
  p_transaccion varchar
)
RETURNS varchar AS
$body$
/**************************************************************************
 SISTEMA:		Organigrama
 FUNCION: 		orga.ft_cargo_ime
 DESCRIPCION:   Funcion que gestiona las operaciones basicas (inserciones, modificaciones, eliminaciones de la tabla 'orga.tcargo'
 AUTOR: 		 (admin)
 FECHA:	        14-01-2014 19:16:06
 COMENTARIOS:	
***************************************************************************
 HISTORIAL DE MODIFICACIONES:

	
     HISTORIAL DE MODIFICACIONES:
  ISSUE                FECHA                AUTOR                DESCRIPCION
 #0                14-01-2014                                 creacion
 #30               15-07-2019       RAC                       adiciona tipo de cargo 
 #57               04-08-2019       JUAN                      Permitir editar escala salarial 
 #68               25-09-2019       JUAN                      Corrección de editado en cargos
 #73               03-10-2019       JRR                       Agregar validacion al modificar un cargo, no debe dejar modificar la escala si el cargo ya fue incluido en una planilla
***************************************************************************/

DECLARE

	v_nro_requerimiento    	integer;
	v_parametros           	record;
	v_id_requerimiento     	integer;
	v_resp		            varchar;
	v_nombre_funcion        text;
	v_mensaje_error         text;
	v_id_cargo	integer;
	v_nombre_cargo			varchar;
	v_id_lugar				integer;
    v_id_escala				integer;
			    
BEGIN

    v_nombre_funcion = 'orga.ft_cargo_ime';
    v_parametros = pxp.f_get_record(p_tabla);

	/*********************************    
 	#TRANSACCION:  'OR_CARGO_INS'
 	#DESCRIPCION:	Insercion de registros
 	#AUTOR:		admin	
 	#FECHA:		14-01-2014 19:16:06
	***********************************/

	if(p_transaccion='OR_CARGO_INS')then
					
        begin
        	select id_lugar into v_id_lugar
        	from orga.toficina
        	where id_oficina = v_parametros.id_oficina;
        	
        	
        	
        	
        	--Sentencia de la insercion
        	insert into orga.tcargo(
              id_tipo_contrato,
              id_lugar,
              id_uo,			
              id_escala_salarial,
              codigo,
              nombre,
              fecha_ini,
              estado_reg,
              fecha_fin,
              fecha_reg,
              id_usuario_reg,
              fecha_mod,
              id_usuario_mod,
              id_oficina,
              id_tipo_cargo  --#30
          	) values(
              v_parametros.id_tipo_contrato,
              v_id_lugar,
              v_parametros.id_uo,			
              v_parametros.id_escala_salarial,
              v_parametros.codigo,
              v_parametros.nombre,
              v_parametros.fecha_ini,
              'activo',
              v_parametros.fecha_fin,
              now(),
              p_id_usuario,
              null,
              null,
              v_parametros.id_oficina,
              v_parametros.id_tipo_cargo  -- #30
							
			)RETURNING id_cargo into v_id_cargo;
			
			--Definicion de la respuesta
			v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Cargo almacenado(a) con exito (id_cargo'||v_id_cargo||')'); 
            v_resp = pxp.f_agrega_clave(v_resp,'id_cargo',v_id_cargo::varchar);

            --Devuelve la respuesta
            return v_resp;

		end;

	/*********************************    
 	#TRANSACCION:  'OR_CARGO_MOD'
 	#DESCRIPCION:	Modificacion de registros
 	#AUTOR:		admin	
 	#FECHA:		14-01-2014 19:16:06
	***********************************/

	elsif(p_transaccion='OR_CARGO_MOD')then

		begin
		
        	select c.id_escala_salarial into v_id_escala
            from orga.tcargo c
            where id_cargo = v_parametros.id_cargo;
            
            --si se modifica la escala salarial garantizar que no fue utilizada en una planilla
            if (v_id_escala != v_parametros.id_escala_salarial and EXISTS(select 1 FROM information_schema.schemata WHERE schema_name = 'plani')) THEN
            	if (exists 	(select 1 
                			from plani.tfuncionario_planilla fp
                            inner join orga.tuo_funcionario uf on fp.id_uo_funcionario = uf.id_uo_funcionario
                            where uf.id_cargo = v_parametros.id_cargo)
            		) then
                	raise exception 'No es posible modificar la escala salarial de este cargo ya que el cargo fue utilizado en una planilla';
                end if;
            end if;
            
        	select id_lugar into v_id_lugar
        	from orga.toficina
        	where id_oficina = v_parametros.id_oficina;
			
			--Sentencia de la modificacion
			update orga.tcargo set
              id_lugar = v_id_lugar,
              codigo = v_parametros.codigo,			
              fecha_ini = v_parametros.fecha_ini,
              fecha_fin = v_parametros.fecha_fin,
              fecha_mod = now(),
              id_usuario_mod = p_id_usuario,			
              id_oficina = v_parametros.id_oficina,
              id_tipo_cargo = v_parametros.id_tipo_cargo,  --#30
              id_escala_salarial=v_parametros.id_escala_salarial, -- #57 
              nombre = v_parametros.nombre --#68
			where id_cargo=v_parametros.id_cargo;
               
			--Definicion de la respuesta
            v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Cargo modificado(a)'); 
            v_resp = pxp.f_agrega_clave(v_resp,'id_cargo',v_parametros.id_cargo::varchar);
               
            --Devuelve la respuesta
            return v_resp;
            
		end;

	/*********************************    
 	#TRANSACCION:  'OR_CARGO_ELI'
 	#DESCRIPCION:	Eliminacion de registros
 	#AUTOR:		admin	
 	#FECHA:		14-01-2014 19:16:06
	***********************************/

	elsif(p_transaccion='OR_CARGO_ELI')then

		begin
		
			if (exists (select 1 from orga.tuo_funcionario
						where estado_reg = 'activo' and (fecha_finalizacion > now()::date or fecha_finalizacion is null) 
							and id_cargo = v_parametros.id_cargo))then
				raise exception 'No es posible eliminar un cargo asignado a un empleado';
			end if;
			--Sentencia de la eliminacion
			update orga.tcargo
			set estado_reg = 'inactivo'
            where id_cargo=v_parametros.id_cargo;
               
            --Definicion de la respuesta
            v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Cargo eliminado(a)'); 
            v_resp = pxp.f_agrega_clave(v_resp,'id_cargo',v_parametros.id_cargo::varchar);
              
            --Devuelve la respuesta
            return v_resp;

		end;
         
	else
     
    	raise exception 'Transaccion inexistente: %',p_transaccion;

	end if;

EXCEPTION
				
	WHEN OTHERS THEN
		v_resp='';
		v_resp = pxp.f_agrega_clave(v_resp,'mensaje',SQLERRM);
		v_resp = pxp.f_agrega_clave(v_resp,'codigo_error',SQLSTATE);
		v_resp = pxp.f_agrega_clave(v_resp,'procedimientos',v_nombre_funcion);
		raise exception '%',v_resp;
				        
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
