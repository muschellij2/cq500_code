cd $dex/CQ500/code

# n=200
n=130

Rnosave get_directories.R -N FILES

Rnosave convert_files.R -N SS -t 1-${n}

Rnosave n4.R -N N4 -hold_jid_ad SS \
	-t 1-${n} -l mem_free=15G,h_vmem=16G

# Rnosave n4.R -N N4 -hold_jid_ad SS \
# 	-l mem_free=30G,h_vmem=32G \
# 	-t 215,230	

Rnosave pitch_segment.R -N PITCH -hold_jid_ad PITCH \
	-l mem_free=30G,h_vmem=32G \
	-t 1-1273
	
Rnosave seg.R -t 18,37 \
  -l mem_free=78G,h_vmem=80G -N SEG
	
# Rnosave pitch_segment.R -N PITCH2 -hold_jid_ad PITCH \
# 	-l mem_free=40G,h_vmem=42G \
# 	-t 216

cd $dex/CQ500/code

i=2
ntemp=130
for i in {1..5}; 
do
	i_before=$[i-1]

	Rnosave template_registration.R -t 1-${ntemp} \
	-N TEMP${i} -l mem_free=20G,h_vmem=22G \
	-hold_jid AVG${i_before} \
	-hold_jid TEMP${i_before} 

	grep spool TEMP*.*
	grep rror TEMP*.*

	Rnosave average_template.R \
	-l mem_free=138G,h_vmem=140G -N AVG${i} \
	-hold_jid TEMP${i}
	
done

