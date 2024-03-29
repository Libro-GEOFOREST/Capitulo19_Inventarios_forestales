#Establecer el directorio de trabajo
setwd("C:/DESCARGA/")

#Cargar librer�a para leer archivos shapefile
library(sf)
Pinar.Yunquera<-st_read("C:/DESCARGA/Pinar.Yunquera.shp") #Adaptar a la ruta en la que se haya guardado en el equipo

#Activar el paquete para leer tabla de excel
library(readxl)

#Leer tabla de excel, hoja de localizacion de parcelas
Inventario <- read_excel("DATOS_INVENTARIO.xls",sheet=1)

#Leer tabla de excel, hoja de datos dasom�tricos
Pies.mayores<-read_excel("DATOS_INVENTARIO.xls",sheet=3)

#Leer tabla de excel, hojas de datos dasom�tricos
Arboles.tipo<-read_excel("DATOS_INVENTARIO.xls",sheet=2)

#Leer tabla de excel, hojas de regeneraci�n
Regeneracion<-read_excel("DATOS_INVENTARIO.xls",sheet=4)

#Leer tabla de excel, hojas de matorral
Matorral<-read_excel("DATOS_INVENTARIO.xls",sheet=5)

#Convertir la tabla en un data frame
Inventario<-as.data.frame(Inventario)
Arboles.tipo<-as.data.frame(Arboles.tipo)
Pies.mayores<-as.data.frame(Pies.mayores)
Regeneracion<-as.data.frame(Regeneracion)
Matorral<-as.data.frame(Matorral)


#Ver la tabla de datos
View(Inventario)



#Activaci�n de la librer�a necesaria
library(sf)

#Convertir data frame a SpatialPointsDataFrame
Inventario.sp <- st_as_sf(x=Inventario,coords=c("X","Y"), crs=23030)

#Representaci�n cartogr�fica de las parcelas
library(mapview)

mapview(Inventario.sp,map.type = "Esri.WorldImagery")


#Nombres de las columnas de la tabla de pies mayores
colnames(Pies.mayores)

#Resumen de la tabla por columnas
summary(Pies.mayores)

#Se eliminan columnas en blanco
Pies.mayores<-Pies.mayores[,c(1:5)]

#Resumen de especies presentes
summary(as.factor(Pies.mayores$'C�DIGO ESPECIE'))

#Especies presentes por parcela
Especies<-as.data.frame.matrix(table(Pies.mayores$'N� PARCELA',
                                     Pies.mayores$'C�DIGO ESPECIE'))

#Introducir el numero de parcela correspondiente en la tabla
Especies$Parcela<-rownames(Especies)

#Seleccionar las especies de estudio
Especies<-Especies[,c("24","32","37","39","Parcela")]

#Cambiar nombres de las columnas
colnames(Especies)<-c("P.halepensis","A.pinsapo","J.communis","J.phoenica","Parcela")

#Valores por hectarea
Especies$P.halepensis<-Especies$P.halepensis*10000/(pi*(13^2))
Especies$A.pinsapo<-Especies$A.pinsapo*10000/(pi*(13^2))
Especies$J.communis<-Especies$J.communis*10000/(pi*(13^2))
Especies$J.phoenica<-Especies$J.phoenica*10000/(pi*(13^2))

#Unir parcelas con Especies
Especies.sp<-merge(Inventario.sp,Especies,by.x="N� PARCELA",by.y="Parcela")

#Valor medio de la densidad en P.halepensis
mean(Especies.sp$P.halepensis[Especies.sp$P.halepensis>0])

#Densidad m�xima de P.halepensis
max(Especies.sp$P.halepensis)

#Densidad m�nima en P.halepensis
min(Especies.sp$P.halepensis[Especies.sp$P.halepensis>0])

#Cartograf�a de densidad de Especies
plot(Especies.sp[,c("P.halepensis","A.pinsapo","J.communis","J.phoenica")], pch=16, 
     axes=TRUE)

#Cartograf�a de densidad de Pinsapo
mapview(Especies.sp,zcol="A.pinsapo", map.type = "Esri.WorldImagery")

# install.packages("gstat")
library(gstat)
#Funci�n de predicci�n geoestad�stica
modelo.pinsapo <- gstat(formula=A.pinsapo~1,
                        locations=Especies.sp, nmax=5, set=list(idp = 0))

#Generar raster de 20 m de pixel con la extensi�n del inventario
library(raster)

r<-raster(Especies.sp,res=20)
nn.dens.pinsapo <- interpolate(r, modelo.pinsapo)


#Consulta de los sistemas de referencia de las capas necesarias
crs(Pinar.Yunquera)

crs(Especies.sp)

#Cambiar los sistemas de referencia para que coincidan
Pinar.Yunquera<-st_transform(Pinar.Yunquera,
                             crs=st_crs(Especies.sp))

#Comprobaci�n del sistema de referencia
crs(Pinar.Yunquera)

#Calcular diametro normal medio
Arboles.tipo$DN<-(Arboles.tipo$DN1+Arboles.tipo$DN2)/2

#Gr�fico de alturas en funci�n de los di�metros
plot(Arboles.tipo$DN[which(Arboles.tipo$'C�DIGO ESPECIE'==24)],
     Arboles.tipo$HT[which(Arboles.tipo$'C�DIGO ESPECIE'==24)],
     pch=19,col=rgb(0,0,0,0.15),
     xlab="DAP (cm)",ylab="Altura (m)",main="P. halepensis")

#Creacion del modelo
modelo.h.halepensis<-lm(Arboles.tipo$HT[which(Arboles.tipo$'C�DIGO ESPECIE'==24)]~log(Arboles.tipo$DN[which(Arboles.tipo$'C�DIGO ESPECIE'==24)]))

#Resumen del modelo
summary(modelo.h.halepensis)

#Coeficiente de determinaci�n
RSQ.halepensis<-summary(modelo.h.halepensis)$r.squared
RSQ.halepensis

#Correlaciones predicho vs observado
correlaciones.halepensis<-cor(modelo.h.halepensis$fitted.values,
                              Arboles.tipo$HT[which(Arboles.tipo$'C�DIGO ESPECIE'==24)])
correlaciones.halepensis

#Gr�fico de alturas en funci�n de los di�metros frente al modelo
plot(Arboles.tipo$DN[which(Arboles.tipo$'C�DIGO ESPECIE'==24)],
     Arboles.tipo$HT[which(Arboles.tipo$'C�DIGO ESPECIE'==24)],
     pch=19,col=rgb(0,0,0,0.15),
     xlab="DAP (cm)",ylab="Altura (m)",main="P. halepensis")
lines(sort((Arboles.tipo$DN[which(Arboles.tipo$'C�DIGO ESPECIE'==24)])),
      sort(modelo.h.halepensis$fitted.values),lwd=2,col="red")
legend("bottomright", 
       legend=c(paste0("r=",round(correlaciones.halepensis,2)),
                as.expression(bquote(R^2==.(round(RSQ.halepensis,2))))),
       bty="n")

#Coeficientes del modelo
modelo.h.halepensis$coefficients

#Aplicaci�n del modelo
Pies.mayores$HT[which(Pies.mayores$'C�DIGO ESPECIE'==24)]<-
  modelo.h.halepensis$coefficients[1]+
  (modelo.h.halepensis$coefficients[2]*(log(Pies.mayores$DN[which(Pies.mayores$'C�DIGO ESPECIE'==24)])))

#N� de pies por parcela equivalente a 100 pies
m<-round((13^2)*pi*100/10000,0)

#Crear matriz vac�a para almacenar valores de alturas de los pies m�s gordos
Ho_PARC.24<-as.matrix(mat.or.vec(m,length(levels(as.factor(Inventario$'N� PARCELA')))))

#Nombrar las parcelas
colnames(Ho_PARC.24)<-levels(as.factor(Inventario$'N� PARCELA'))

#Extraer los m valores de alturas de los m pies con mayor DN
for (i in seq(levels(as.factor(Inventario$'N� PARCELA')))){ 
  PARC_k<-Pies.mayores[which(Pies.mayores$'N� PARCELA'==levels(as.factor(Pies.mayores$'N� PARCELA'))[i]&
                               Pies.mayores$'C�DIGO ESPECIE'==24),]
  Ho_PARC.24[,i]<-as.vector(PARC_k$HT[order(PARC_k$DN,
                                            decreasing =TRUE)][c(1:m)])
}

#Valor medio de dichos valores de altura por parcela
Ho.24<-colMeans(Ho_PARC.24,na.rm=TRUE)
Ho.24<-as.matrix(Ho.24)
colnames(Ho.24)<-"Ho_24"
Ho.24<-as.data.frame(Ho.24)
Ho.24$Parcela<-rownames(Ho.24)

#Resumen de valores de altura dominante de P.halepensis en el monte
mean(Ho.24$Ho_24,na.rm=TRUE)

max(Ho.24$Ho_24,na.rm=TRUE)

#Unir resultado con la tabla de Especies 
Especies.sp<-merge(Especies.sp,Ho.24,by.x="N� PARCELA",
                   by.y="Parcela")

#Sustituci�n de valores nulos por 0
Especies.sp$Ho_24[is.na(Especies.sp$Ho_24)]<-0

#Gr�fico de alturas dominantes de P.halepensis seg�n las parcelas
plot(Especies.sp[,"Ho_24"], pch=16,axes=TRUE, 
     main="Distribuci�n de altura dominante (m) de P.halepensis")

#Funci�n de predicci�n geoestad�stica
modelo.dist.a.halepensis <- gstat(formula=Ho_24~1,
                                  locations=Especies.sp, nmax=5, set=list(idp = 0))

nn.a.halepensis <- interpolate(r, modelo.dist.a.halepensis)

#Enmascarar la superficie del monte
nnmsk.a.halepensis <- mask(nn.a.halepensis, 
                           as_Spatial(st_geometry(Pinar.Yunquera)))

#Mapa de distribuci�n de alturas dominantes de P.halepensis
plot(nnmsk.a.halepensis,main="Distribuci�n de altura dominante (m) de P.halepensis")

#Calcular el �rea basim�trica (g) de cada pie
Pies.mayores$g<-pi*(((Pies.mayores$DN/100)/2)^2)

#Calcular el �rea basim�trica de cada especie en cada parcela
Area.Basimetrica<-aggregate(Pies.mayores$g,
                            by=list(Pies.mayores$'N� PARCELA',
                                    Pies.mayores$'C�DIGO ESPECIE'), FUN=sum)

#Cambiar nombres de los campos
names(Area.Basimetrica)<-c("Parcela","Especie","G")

#�rea basim�trica por hectarea
Area.Basimetrica$G<-Area.Basimetrica$G*10000/(pi*((13/2)^2))

#�rea basim�trica por hectarea
Area.Basimetrica.24<-Area.Basimetrica[which(Area.Basimetrica$Especie==24),]

#Valor medio de �rea basim�trica de P.halepensis en el monte
mean(Area.Basimetrica.24$G,na.rm=TRUE)

#Valor m�ximo de �rea basim�trica de P.halepensis en el monte
max(Area.Basimetrica.24$G,na.rm=TRUE)

#Valor m�nimo de �rea basim�trica de P.halepensis en el monte
min(Area.Basimetrica.24$G,na.rm=TRUE)

#Cambiar nombre al campo G
names(Area.Basimetrica.24)[3]<-"G.24"

#Unir resultado con la tabla de Especies 
Especies.sp<-merge(Especies.sp,Area.Basimetrica.24[,c(1,3)],
                   by.x="N� PARCELA",
                   by.y="Parcela",all.x=TRUE)

#Sustituci�n de valores nulos por 0
Especies.sp$G.24[is.na(Especies.sp$G.24)]<-0

#Gr�fico de �rea basim�trica de P.halepensis seg�n las parcelas
plot(Especies.sp[,"G.24"], pch=16,axes=TRUE, 
     main="Distribuci�n de �rea basal de P.halepensis")

#Funci�n de predicci�n geoestad�stica
modelo.dist.g.halepensis <- gstat(formula=G.24~1,
                                  locations=Especies.sp, nmax=5, set=list(idp = 0))

nn.g.halepensis <- interpolate(r, modelo.dist.g.halepensis)

#Enmascarar la superficie del monte
nnmsk.g.halepensis <- mask(nn.g.halepensis, 
                           as_Spatial(st_geometry(Pinar.Yunquera)))

#Mapa de distribuci�n de alturas dominantes de P.halepensis
plot(nnmsk.g.halepensis,main="Distribuci�n de �rea basal de P.halepensis")

#Indicar que no hay datos en coordenada z
Pinar.Yunquera<-st_zm(Pinar.Yunquera,drop=TRUE)

#Enmascarar la superficie del monte
nn.dens.pinsapo.msk <- mask(nn.dens.pinsapo,
                            as_Spatial(st_geometry(Pinar.Yunquera)))
plot(nn.dens.pinsapo.msk)

